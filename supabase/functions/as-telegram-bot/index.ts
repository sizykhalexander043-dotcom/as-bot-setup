import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { Bot, InlineKeyboard, webhookCallback } from "npm:grammy@1.34.0";
import { createClient } from "npm:@supabase/supabase-js@2";

const token = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const webhookSecret = Deno.env.get("TELEGRAM_WEBHOOK_SECRET") ?? "";
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
let supabaseSecret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
if (!supabaseSecret && secretKeysRaw) {
  try { supabaseSecret = JSON.parse(secretKeysRaw)["default"] ?? ""; }
  catch { console.error("Invalid SUPABASE_SECRET_KEYS JSON"); }
}
const bot = token ? new Bot(token) : null;
const db = supabaseUrl && supabaseSecret ? createClient(supabaseUrl, supabaseSecret, { auth: { persistSession: false } }) : null;

const menu = () => new InlineKeyboard()
  .text("Услуги и цены", "services").row()
  .text("Записаться", "booking").row()
  .text("Абонементы и бонусы", "loyalty").row()
  .text("Адрес и контакты", "contacts").row()
  .text("Задать вопрос", "support");

if (bot) {
  bot.command("start", (ctx) => ctx.reply("АС — студия массажа\n\nДобро пожаловать! Здесь можно ознакомиться с услугами, узнать о записи и связаться со студией.\n\nПока бот работает в информационном режиме. Регистрация и сохранение контактных данных будут включены после настройки согласий на обработку персональных данных.", { reply_markup: menu() }));
  bot.command("help", (ctx) => ctx.reply("Выберите раздел в меню.", { reply_markup: menu() }));
  bot.callbackQuery("services", async (ctx) => {
    await ctx.answerCallbackQuery();
    if (!db) return ctx.reply("Каталог пока настраивается.");
    const { data, error } = await db.from("services").select("name, description, duration_minutes, price_rub").eq("is_active", true).order("price_rub", { ascending: true });
    if (error) { console.error("Services query failed", error.message); return ctx.reply("Не удалось загрузить каталог. Попробуйте позже."); }
    if (!data?.length) return ctx.reply("Каталог услуг пока заполняется.");
    const lines = data.map((s) => "• " + s.name + " — " + Number(s.price_rub).toLocaleString("ru-RU") + " ₽ / " + s.duration_minutes + " мин" + (s.description ? "\n" + s.description : ""));
    return ctx.reply("Услуги студии:\n\n" + lines.join("\n\n"), { reply_markup: menu() });
  });
  bot.callbackQuery("booking", async (ctx) => { await ctx.answerCallbackQuery(); return ctx.reply("Онлайн-запись подключим после проверки интеграции с DIKIDI. Пока запись доступна через администратора студии.", { reply_markup: menu() }); });
  bot.callbackQuery("loyalty", async (ctx) => { await ctx.answerCallbackQuery(); return ctx.reply("Раздел абонементов и бонусной программы появится после настройки безопасной регистрации клиента.", { reply_markup: menu() }); });
  bot.callbackQuery("contacts", async (ctx) => { await ctx.answerCallbackQuery(); return ctx.reply("АС — студия массажа\nг. Владивосток, ул. Сахалинская, 41г\nФитнес-клуб «Платинум», 4 этаж", { reply_markup: menu() }); });
  bot.callbackQuery("support", async (ctx) => { await ctx.answerCallbackQuery(); return ctx.reply("Раздел связи с администратором подключим следующим этапом.", { reply_markup: menu() }); });
}

const page = `<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Подключение бота</title></head><body><main style="font-family:Arial,sans-serif;max-width:520px;margin:40px auto;padding:20px"><h2>Подключение Telegram-бота</h2><p>Введите секрет Webhook, сохранённый в настройках Supabase. Он будет отправлен методом POST, не через адресную строку.</p><form method="POST" action=""><input type="hidden" name="action" value="install"><input type="password" name="secret" required autocomplete="off" placeholder="TELEGRAM_WEBHOOK_SECRET" style="box-sizing:border-box;width:100%;padding:14px;font-size:16px"><button type="submit" style="margin-top:14px;padding:14px 18px;font-size:16px">Установить Webhook</button></form></main></body></html>`;

async function installWebhook(req: Request): Promise<Response> {
  if (!token || !webhookSecret) return Response.json({ error: "Настройки бота не найдены" }, { status: 503 });
  let submitted = "";
  try {
    const form = await req.formData();
    submitted = String(form.get("secret") ?? "");
  } catch { return new Response("Некорректная форма", { status: 400 }); }
  if (submitted !== webhookSecret) return new Response("Неверный секрет. Вернитесь назад и проверьте значение.", { status: 401 });
  if (!/^[A-Za-z0-9_-]{1,256}$/.test(webhookSecret)) return new Response("Формат TELEGRAM_WEBHOOK_SECRET недопустим. Используйте 1–256 символов: латинские буквы, цифры, _ или -.", { status: 400 });
  const webhookUrl = "https://qsiderzmnpjjvccgzels.supabase.co/functions/v1/as-telegram-bot";
  const tg = await fetch("https://api.telegram.org/bot" + token + "/setWebhook", {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url: webhookUrl, secret_token: webhookSecret, allowed_updates: ["message", "callback_query"], drop_pending_updates: false }),
  });
  const result = await tg.json();
  if (!tg.ok || !result.ok) {
    console.error("Telegram setWebhook failed", result.description ?? tg.status);
    return Response.json({ error: "Telegram не принял Webhook", details: result.description ?? "Unknown error" }, { status: 502 });
  }
  const infoResponse = await fetch("https://api.telegram.org/bot" + token + "/getWebhookInfo");
  const info = await infoResponse.json();
  return Response.json({ success: true, message: "Webhook установлен", webhook: { url: info.result?.url ?? webhookUrl, pending_update_count: info.result?.pending_update_count ?? null } });
}

Deno.serve(async (req: Request) => {
  const path = new URL(req.url).pathname;
  if (req.method === "GET" && (path.endsWith("/setup") || path.endsWith("/as-telegram-bot"))) {
    return new Response(page, { status: 200, headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" } });
  }
  if (req.method === "POST") {
    const contentType = req.headers.get("content-type") ?? "";
    if (contentType.includes("application/x-www-form-urlencoded") || contentType.includes("multipart/form-data")) {
      return await installWebhook(req);
    }
    if (!bot || !db || !webhookSecret) return Response.json({ error: "Bot secrets are not configured" }, { status: 503 });
    const receivedSecret = req.headers.get("x-telegram-bot-api-secret-token");
    console.warn("Webhook secret diagnostic", {
      headerPresent: receivedSecret !== null,
      headerLength: receivedSecret?.length ?? 0,
      configuredPresent: Boolean(webhookSecret),
      configuredLength: webhookSecret.length,
      matches: receivedSecret === webhookSecret,
    });
    if (receivedSecret !== webhookSecret) return new Response("Unauthorized", { status: 401 });
    try { return await webhookCallback(bot, "std/http", { secretToken: webhookSecret })(req); }
    catch (error) { console.error("Telegram update failed", error); return Response.json({ error: "Update failed" }, { status: 500 }); }
  }
  return new Response("Method not allowed", { status: 405 });
});
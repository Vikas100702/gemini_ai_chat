/**
 * ============================================================================
 * FILE: backend/src/config/env.ts
 * ROLE: Defensive Runtime Environment Validator & Configuration Guard (Security Gate)
 *
 * WHY THIS FILE EXISTS:
 * In Node.js, accessing `process.env.GEMINI_API_KEY` randomly across multiple files is
 * dangerous—if a key is missing in `.env`, the server starts up fine and crashes later
 * when a real user sends a message.
 *
 * WHAT WE DO HERE:
 * 1. Read all variables from the `.env` file using `dotenv`.
 * 2. Strictly validate their presence and data types (string, number, enum) using `Zod`.
 * 3. Enforce the "Fail-Fast" principle: if anything is missing or wrong, crash immediately
 *    at startup with a clear error message before opening any network port.
 * 4. Freeze (`Object.freeze`) the validated object so no file can accidentally overwrite settings.
 * ============================================================================
 */



// 'dotenv' ek library hai jo aapke computer par rakhi hidden '.env' file ko padhti hai
// aur uske andar likhe variables (jaise PORT=3000) ko Node.js ke memory (process.env) me daalti hai.
import dotenv from 'dotenv';

// 'z' (Zod) ek validation library hai. Ye check karti hai ki jo data aa raha hai
// wo sahi format me hai ya nahi (jaise PORT ek number hi hona chahiye, text nahi).
import { z } from 'zod';

dotenv.config(); // Load variables from .env file into process.env

// Yahan hum ek 'Schema' (Niyam/Rules) bana rahe hain ki humare server ko chalne ke liye
// kaun-kaun se variables chahiye aur unka type kya hona chahiye.
const envSchema = z.object({
  // NODE_ENV sirf in 3 values me se ek ho sakta hai. Agar kuch nahi diya toh default 'development' maan lega.
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // '.env' file me sab kuch text (string) hota hai. 'z.coerce.number()' us text "3000" ko
  // zabardasti asli number 3000 me badal deta hai. Default 3000 rakha hai.
  PORT: z.coerce.number().default(3000),

  // Server kis IP address par chalega. '0.0.0.0' ka matlab hai ki local network (mobile/emulator) se bhi connect ho sake.
  HOST: z.string().default('0.0.0.0'),

  // CORS_ORIGIN batata hai ki kaunse frontend URLs ko is backend se baat karne ki permission hai.
  CORS_ORIGIN: z.string().default('*'),

  // GEMINI_API_KEY kam se kam 1 character ki string honi hi chahiye (khali nahi chalegi).
  GEMINI_API_KEY: z.string().min(1, 'GEMINI_API_KEY is required for the AI chat service'),
});

// 'process.env' Node.js ka built-in global object hai jisme system ke saare environment variables hote hain.
// 'safeParse' bina crash kiye check karta hai ki 'process.env' humare upar banaye gaye 'envSchema' rules par khara utarta hai ya nahi.
const parsedEnv = envSchema.safeParse(process.env);

// Agar validation fail ho gayi (jaise GEMINI_API_KEY missing hai):
if (!parsedEnv.success) {
  // eslint-disable-next-line no-console
  console.error('❌ FATAL: Invalid runtime environment configuration:');
  // Error ko saaf JSON format me print karo taaki developer ko turant dikhe ki kya missing hai.
  // eslint-disable-next-line no-console
  console.error(JSON.stringify(parsedEnv.error.format(), null, 2));

  // 'process.exit(1)' Node.js ko turant band (kill) kar deta hai.
  // '1' ka matlab hai ki program kisi error ki wajah se band hua hai (0 ka matlab normal exit hota hai).
  process.exit(1);
}

// 'Object.freeze()' is object ko lock kar deta hai (Read-Only bana deta hai).
// Ab pure project me koi bhi file galti se 'env.PORT = 5000' karke value badal nahi payegi.
export const env = Object.freeze(parsedEnv.data);

// 'type Env' TypeScript ko batata hai ki 'env' object ke andar kya-kya properties hain (auto-complete ke liye).
export type Env = z.infer<typeof envSchema>;

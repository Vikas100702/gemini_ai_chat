/**
 * ============================================================================
 * FILE: backend/src/shared/utils/logger.ts
 * ROLE: High-Performance Asynchronous Structured Logger (Observability Engine)
 *
 * WHY THIS FILE EXISTS:
 * Standard `console.log()` in Node.js is synchronous—it blocks the single-threaded
 * Event Loop while writing text to the terminal, slowing down API responses under load.
 * Also, raw console text cannot be easily searched or filtered on cloud servers.
 *
 * WHAT WE DO HERE:
 * 1. Initialize `Pino`, an ultra-fast, non-blocking JSON logger.
 * 2. In `development` mode, format logs using `pino-pretty` so they appear colorful
 *    and human-readable in your VS Code terminal.
 * 3. In `production` mode, output raw single-line JSON logs with timestamps and log levels
 *    (`info`, `warn`, `error`, `fatal`) ready for cloud monitoring tools.
 * ============================================================================
 */

// 'pino' humari high-speed logging library hai.
// '{ type LoggerOptions }' TypeScript ko batata hai ki hum Pino ke settings ka blueprint (type) import kar rahe hain.
import pino, { LoggerOptions } from 'pino';

// Humne jo 'env.ts' me safe config banaya tha, use yahan mangwa rahe hain
// taaki pata chal sake ki app 'development' me chal raha hai ya 'production' me.
import { env } from '../../config/env.js';

// Ye check karta hai ki kya hum abhi apne laptop par coding kar rahe hain ('development')?
// Agar haan, toh 'isDev' ki value 'true' ho jayegi, warna 'false'.
const isDev = env.NODE_ENV === 'development';

// Yahan hum logger ke basic rules (options) set kar rahe hain.
// ': LoggerOptions' likhne se TypeScript humein auto-complete dega aur galat setting likhne par rokega.
const loggerOptions: LoggerOptions = {
  // 'level' batata hai ki kitni detail me logs dikhane hain:
  // 'debug' = choti se choti har baat print karo (laptop par testing ke liye).
  // 'info' = sirf kaam ki zaroori baatein print karo (live server/production ke liye).
  level: isDev ? 'debug' : 'info',
};

if (isDev) {
  // Agar hum development mode me hain, toh raw JSON logs padhne me mushkil hote hain.
  // Isliye hum 'transport' lagate hain jo un logs ko sundar aur colorful bana deta hai.
  loggerOptions.transport = {
    // 'pino-pretty' wo tool hai jo terminal me colored aur formatted logs dikhata hai.
    target: 'pino-pretty',
    options: {
      colorize: true, // Logs ko alag-alag rang (green, yellow, red) deta hai.
      translateTime: 'SYS:yyyy-mm-dd HH:MM:ss.l', // Time ko readable format (2026-11-12 13:09:00) me dikhata hai.
      ignore: 'pid,hostname', // Process ID aur computer ka naam chhupa deta hai taaki terminal saaf dikhe.
    },
  };
}

// Finally, upar banayi gayi settings ke saath 'logger' ko chalu (initialize) karke export kar rahe hain.
// Ab pure project me koi bhi file 'logger.info()' ya 'logger.error()' use kar sakti hai.
export const logger = pino(loggerOptions);

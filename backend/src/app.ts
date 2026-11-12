/**
 * ============================================================================
 * FILE: backend/src/app.ts
 * ROLE: Fastify Application Factory (Assembling Plugins, Security & Routes)
 *
 * WHY THIS FILE EXISTS:
 * In enterprise Node.js architecture, we strictly separate "building the app" (`app.ts`)
 * from "starting the network server" (`server.ts`).
 * Why? Because later, when we write automated tests, we can import `buildApp()` and test
 * our API endpoints directly in memory without opening a real network port (like 3000).
 *
 * WHAT WE DO HERE:
 * 1. Create a Fastify instance connected to our custom Pino `logger`.
 * 2. Register `@fastify/helmet` to inject defensive HTTP security headers.
 * 3. Register `@fastify/cors` so your Flutter app (mobile/web) can safely talk to this backend.
 * 4. Plug in our modular routes (`healthRoutes`) under the `/api/v1` URL prefix.
 * ============================================================================
 */

// 'fastify' main framework function hai.
// 'FastifyInstance' aur 'FastifyBaseLogger' TypeScript ke blueprints (types) hain.
import fastify, { FastifyBaseLogger, type FastifyInstance } from 'fastify';

// '@fastify/cors' browser aur mobile security rules (Cross-Origin Resource Sharing) handle karta hai.
import cors from '@fastify/cors';

// '@fastify/helmet' hackers se bachne ke liye HTTP response me security headers lagata hai.
import helmet from '@fastify/helmet';

// '@fastify/helmet' hackers se bachne ke liye HTTP response me security headers lagata hai.
import { env } from './config/env.js';
import { logger } from './shared/utils/logger.js';

// Health module ke routes ko import kar rahe hain.
import { healthRoutes } from './modules/health/health.routes.js';

// 'buildApp' ek async factory function hai jo ek complete, ready-to-run Fastify server banakar return karta hai.
export async function buildApp(): Promise<FastifyInstance> {
  // 1. Fastify ka naya instance (object) banaya
  const app = fastify({
    // Fastify ke default logger ki jagah hum apna custom Pino logger de rahe hain.
    // 'as FastifyBaseLogger' TypeScript ko batata hai ki Pino logger Fastify ke rules par khara utarta hai.
    loggerInstance: logger as FastifyBaseLogger,

    // 'false' rakhne se Fastify har incoming request (req-1, req-2) aur uske response time ko
    // automatically terminal me log karega
    disableRequestLogging: false,
  });

  // 2. Enterprise Security Headers (Helmet)
  // 'await app.register()' Fastify me kisi bhi plugin ko jodne ka standard tarika hai.
  await app.register(helmet, {
    // Content Security Policy (CSP) sirf live production me on rakhte hain taaki local testing me dikkat na aaye.
    contentSecurityPolicy: env.NODE_ENV === 'production',
  });

  // 3. Client CORS Integration
  // Ye batata hai ki kaunse frontend apps is backend ko call kar sakte hain
  await app.register(cors, {
    // Agar `.env` me `CORS_ORIGIN=*` hai, toh `true` set karo (sabko allow karo — local dev ke liye).
    // Agar koi specific domain diya hai (jaise `https://iter.app`), toh sirf usi ko allow karo.
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN,

    // Sirf in HTTP methods ko allow kar rahe hain:
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  });

  // 4. Register API Routes
  // Yahan hum `healthRoutes` ko `/api/v1` prefix ke saath jod rahe hain.
  // Isliye `health.routes.ts` ka `/health` automatically `/api/v1/health` ban jaata hai.
  // API versioning (`/api/v1`) enterprise standard hai taaki future me `/api/v2` bina purane Flutter app ko tode ban sake.
  await app.register(healthRoutes, { prefix: '/api/v1' });

  return app; // Taiyar Fastify app ko caller (`server.ts`) ko wapas return kar diya.
}

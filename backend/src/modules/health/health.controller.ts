/**
 * ============================================================================
 * FILE: backend/src/modules/health/health.controller.ts
 * ROLE: HTTP Transport Controller (Traffic Police / Translator)
 *
 * WHY THIS FILE EXISTS:
 * In Clean Architecture, the Service (`health.service.ts`) only understands plain
 * JavaScript data—it does NOT know what an HTTP request or status code (200, 404) is.
 * We need a "Translator" between the web world (Fastify) and our business logic[cite: 15].
 *
 * WHAT WE DO HERE:
 * 1. Receive the incoming HTTP request (`FastifyRequest`) from Fastify.
 * 2. Call our decoupled `healthService.getHealthStatus()` to fetch the actual data.
 * 3. Attach the proper HTTP status code (`200 OK`) and send JSON back via `FastifyReply`.
 * ============================================================================
 */

// 'FastifyRequest' aur 'FastifyReply' Fastify framework ke built-in blueprints (types) hain.
// 'type' keyword lagane se TypeScript inhe sirf code check karne ke liye use karega.
import type { FastifyReply, FastifyRequest } from 'fastify';

// Apni business logic service ko import kar rahe hain.
// Dhyan dein: ESM standard ke mutabik extension '.js' hi likha jaata hai.
import { healthService } from './health.service.js';

export class HealthController {
  // 'async' batata hai ki ye function asynchronous kaam karega (network par data bhejna).
  // 'Promise<void>' ka matlab hai ki ye function kisi variable me value return nahi karega,
  // balki seedhe 'reply.send()' ke zariye client ko response bhej dega.
  //
  // Parameters:
  // '_req': Incoming request object. Aage underscore '_' isliye lagaya hai taaki TypeScript/ESLint
  //         ko pata rahe ki humne is parameter ko jaan-bujhkar use nahi kiya hai (unused warning se bachne ke liye).
  // 'reply': Fastify ka response object jisse hum client (Flutter/Browser) ko wapas jawab bhejte hain.
  public async check(_req: FastifyRequest, reply: FastifyReply): Promise<void> {
    const status = healthService.getHealthStatus(); // 1. Service layer se saaf-suthra health data mangwaya

    // 2. Client ko HTTP Status 200 (Success) ke saath JSON data wapas bhej diya.
    // 'await' lagane se Fastify ensure karta hai ki response network par poori tarah flush ho jaye.
    await reply.status(200).send(status);
  }
}

// Singleton instance export kar rahe hain taaki routes file me seedhe use ho sake.
export const healthController = new HealthController();

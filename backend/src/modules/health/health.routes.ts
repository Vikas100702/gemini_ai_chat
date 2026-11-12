/**
 * ============================================================================
 * FILE: backend/src/modules/health/health.routes.ts
 * ROLE: Endpoint Routing Table (URL Map for Health Module)
 *
 * WHY THIS FILE EXISTS:
 * Instead of dumping 50 different API URLs (`/login`, `/chat`, `/health`, `/upload`)
 * into one giant `server.ts` file (Monolithic God-File)[cite: 15], each feature module
 * owns its own isolated routes file.
 *
 * WHAT WE DO HERE:
 * 1. Create a Fastify Plugin (`FastifyPluginAsync`) that registers the `/health` URL.
 * 2. Connect the HTTP `GET` method to `healthController.check`.
 * 3. Use `.bind(healthController)` so JavaScript does not lose track of `this` context
 *    when Fastify executes the method later on an incoming request.
 * ============================================================================
 */


// 'FastifyInstance' humare main Fastify server ka type hai.
// 'FastifyPluginAsync' Fastify ka standard tarika hai modular route groups banane ka.
import { FastifyInstance, FastifyPluginAsync } from 'fastify';

// Controller ko import kar rahe hain jo is route par aane wali request ko handle karega.
import { healthController } from './health.controller.js';

// Ye ek async plugin function hai jise 'app.ts' baad me '/api/v1' prefix ke saath register karega.
// Toh '/health' automatically '/api/v1/health' ban jayega.
export const healthRoutes: FastifyPluginAsync = async (fastify: FastifyInstance): Promise<void> => {
  // 'fastify.get()' batata hai ki jab koi client HTTP GET request bheje '/health' par,
  // toh 'healthController.check' function ko chalao.
  //
  // '.bind(healthController)' kyun lagaya?
  // JavaScript me jab kisi class ke method ko callback ke roop me pass karte hain,
  // toh wo apni class ('this') ki pehchan bhool jaata hai. '.bind()' us pehchan ko lock rakhta hai.
  fastify.get('/health', healthController.check.bind(healthController));
};

/**
 * ============================================================================
 * FILE: backend/src/modules/health/health.service.ts
 * ROLE: Health Check Business Logic Layer (Application Service)
 *
 * WHY THIS FILE EXISTS:
 * In Clean Architecture, business logic MUST stay 100% separated from HTTP frameworks
 * (Fastify/Express). This file does not know whether the request came from a browser,
 * a mobile app, a WebSocket, or a terminal command.
 *
 * WHAT WE DO HERE:
 * 1. Define a strict TypeScript interface (`HealthStatus`) describing the exact shape of our response.
 * 2. Collect system metrics from Node.js (`process.uptime()`, current ISO timestamp, environment).
 * 3. Return a clean, plain JavaScript object to the Controller layer[cite: 15].
 * ============================================================================
 */


// 'export interface' TypeScript me ek contract (dhancha) banata hai.
// Ye guarantee deta hai ki jab bhi hum health status bhejenge, usme ye 4 properties
// (status, timestamp, uptimeSeconds, environment) isi exact naam aur type ki hongi.
export interface HealthStatus {
  status: 'ok' | 'degraded'; // Union Type: 'status' ki value sirf 'ok' ya 'degraded' ho sakti hai, koi teesra word nahi.
  timestamp: string;
  uptimeSeconds: number;
  environment: string;
}

// Hum logic ko ek 'class' ke andar organize kar rahe hain taaki code modular aur testable rahe.
export class HealthService {
  // 'public' ka matlab hai ki is method ko class ke bahar (jaise Controller me) call kiya ja sakta hai.
  // ': HealthStatus' batata hai ki ye function return me upar banaya gaya interface hi wapas karega.
  public getHealthStatus(): HealthStatus {
    return {
      status: 'ok',

      // 'new Date().toISOString()' abhi ka exact global time (UTC standard format me) deta hai.
      // Jaise: "2026-11-12T07:46:00.000Z"
      timestamp: new Date().toISOString(),

      // 'process.uptime()' Node.js ka built-in function hai jo batata hai ki server ko start hue
      // kitne seconds ho chuke hain (decimal me, jaise 44.823).
      // 'Math.floor()' decimal hata kar use poora number (44) bana deta hai.
      uptimeSeconds: Math.floor(process.uptime()),

      // Batata hai ki server abhi kis mode me chal raha hai ('development' ya 'production').
      environment: process.env.NODE_ENV || 'development',
    };
  }
}

// Singleton Pattern: Hum class ka ek ready-made object (instance) bana kar export kar rahe hain.
// Taaki baaki files ko baar-baar 'new HealthService()' na likhna pade, wo seedhe 'healthService' use kar sakein.
export const healthService = new HealthService();

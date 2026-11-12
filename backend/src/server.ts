/**
 * ============================================================================
 * FILE: backend/src/server.ts
 * ROLE: Runtime Entry Point & OS Process Lifecycle Manager (The Ignition Switch)
 *
 * WHY THIS FILE EXISTS:
 * When you run `npm run dev` or `node dist/server.js`, Node.js starts executing from here.
 * Beyond simply opening port 3000, an enterprise backend MUST be crash-resistant.
 * If the server crashes abruptly during a database save or AI stream, data gets corrupted.
 *
 * WHAT WE DO HERE:
 * 1. Call `buildApp()` to get our configured Fastify application.
 * 2. Bind the server to `HOST` (`0.0.0.0`) and `PORT` (`3000`) to start accepting traffic.
 * 3. Wire Graceful Shutdown (`SIGTERM`, `SIGINT`): when you press `Ctrl + C` or cloud servers
 *    restart, finish ongoing requests before closing the port.
 * 4. Wire Global Process Safety Nets (`unhandledRejection`, `uncaughtException`) so rogue
 *    asynchronous errors are caught and logged instead of crashing silently.
 * ============================================================================
 */

import { env } from './config/env.js';
import { buildApp } from './app.js';
import { logger } from './shared/utils/logger.js';

// Main startup function
async function bootstrap(): Promise<void> {
  // 1. Pehle `app.ts` se pura server assemble karwaya
  const app = await buildApp();

  // 2. Network Port Open Karna
  try {
    // 'app.listen()' aapke computer ke network card par port 3000 ko listen mode me daalta hai.
    // 'await' ka matlab: jab tak port safely open na ho jaye, agli line par mat jao.
    await app.listen({
      port: env.PORT,
      host: env.HOST,
    });
    logger.info(`🚀 Iter Backend running at http://${env.HOST}:${env.PORT}/api/v1/health`);
  } catch (error) {
    // Agar port 3000 pehle se kisi aur program ne pakad rakha ho, toh error log karke band ho jao.
    logger.fatal({ error }, 'Fatal error during application startup');
    process.exit(1);
  }

  // 3. Graceful Shutdown (Shanti se Server Band Karna)
  // 'SIGINT' = Jab aap terminal me `Ctrl + C` dabate hain.
  // 'SIGTERM' = Jab cloud server (AWS/Docker/Render) aapke container ko band karne ka signal bhejta hai.
  const shutDownSignals: NodeJS.Signals[] = ['SIGTERM', 'SIGINT'];
  for (const signal of shutDownSignals) {
    // 'process.on()' Operating System ke signals ko sunta (listen karta) hai.
    process.on(signal, async () => {
      logger.info(`Received ${signal}. Initiating graceful shutdown...`);
      try {
        // 'await app.close()' naye users ko aane se rokta hai, lekin jo requests pehle se chal rahi hain
        // unhe poora hone deta hai, aur phir port 3000 ko release karta hai.
        await app.close();
        logger.info('HTTP server closed successfully. Process exiting.');

        process.exit(0); // 'process.exit(0)' ka matlab: sab kuch safely band hua, koi error nahi hai.
      } catch (error) {
        logger.error({ error }, 'Error during graceful shutdown');
        process.exit(1);
      }
    });
  }

  // 4. Global Process Safety Nets (Aakhiri Suraksha Kavach)
  // Agar pure codebase me kahin koi async Promise fail ho jaye aur wahan `try/catch` lagana bhool gaye hon,
  // toh Node.js use yahan pakad lega aur error log karega.
  process.on('unhandledRejection', (reason: unknown) => {
    logger.error({ reason }, 'Unhandled Promise Rejection detected');
  });

  // Agar koi synchronous code bina try/catch ke fat jaye (jaise memory corruption),
  // toh fatal log print karke process ko safely exit karo taaki cloud platform naya fresh server start kar sake
  process.on('uncaughtException', (err: Error) => {
    logger.fatal({ err }, 'Uncaught Exception thrown. Shutting down defensively.');
    process.exit(1);
  });
}

// Finally, `bootstrap()` function ko call karke pure engine ko start kar rahe hain.
// 'void' TypeScript/ESLint ko batata hai ki hum jaan-bujhkar is top-level Promise ka return value await nahi kar rahe.
void bootstrap();

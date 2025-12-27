# Guion de Video: Demo del Protocolo de Préstamos Reactivo (Siaduan)

**Duración Estimada:** 4 minutos
**Formato:** Monólogo (Narrador/Demo).
**Escenario Visual:** Captura de pantalla del Frontend de Siaduan (localhost).

---

## 1. Introducción (0:00 - 0:40)

**(Visual: Pantalla de inicio de la aplicación Siaduan)**

Hola a todos. Hoy quiero mostrarles **Siaduan**, un protocolo de préstamos automatizado que hemos construido sobre **Reactive Network**.

Sabemos que en DeFi, obtener el mejor rendimiento suele requerir un monitoreo constante. Mover fondos manualmente entre pools como Aave o Compound cuando cambian las tasas es tedioso y costoso.

Siaduan soluciona esto. Nuestra bóveda inteligente monitorea las tasas en tiempo real y mueve la liquidez automáticamente a donde sea más rentable, sin que tengas que levantar un dedo. Todo esto ocurre de manera descentralizada mediante contratos inteligentes reactivos.

---

## 2. Conexión y Setup (0:40 - 1:15)

**(Visual: Cursor hacia "Connect Wallet")**

Veamos cómo funciona en la práctica. Primero, conectaré mi billetera aquí arriba en **"Connect Wallet"**. Para esta demostración, estamos operando en la red de prueba Sepolia.

**(Visual: Se conecta la wallet)**

Como pueden ver, mi saldo inicial es cero. Para poder interactuar con el protocolo, necesitamos algunos fondos de prueba. He integrado un **Faucet** directamente en la interfaz.

Voy al panel izquierdo y hago clic en **"Mint 1000 Tokens"** para recibir MockUSDC.

**(Visual: Clic en Mint, confirmación)**

Listo, ya tenemos 1000 USDC para empezar.

---

## 3. Depósito Inicial (1:15 - 1:50)

**(Visual: Panel "Lending Vault")**

Ahora, vamos a depositar estos fondos en la bóveda. El sistema administra dos pools simulados: **Pool A** y **Pool B**.

Voy a depositar **500 USDC**. Escribo la cantidad y confirmo la transacción.

**(Visual: Input 500 -> Click Deposit -> Confirmar)**

Perfecto. Si miramos el panel de **"Protocol Status"**, vemos que la bóveda ha recibido los fondos. Por defecto, el sistema asigna la liquidez inicial al **Pool A**.
*   Vemos: Allocation Pool A: 500.
*   Allocation Pool B: 0.

---

## 4. Simulando el Mercado (1:50 - 2:40)

**(Visual: Panel "Rate Control")**

Aquí es donde se pone interesante. Imaginemos que las condiciones del mercado cambian drásticamente. Digamos que el **Pool B** empieza a ofrecer un rendimiento mucho mayor que el Pool A.

Como esto es una demo en testnet, tengo este panel de **"Control de Tasas"** que actúa como nuestro oráculo.
*   El Pool A está pagando un 5%.
*   Voy a subir la tasa del **Pool B** artificialmente al **10%**.

**(Visual: Mover slider Pool B a 10%, Pool A en 5%. Click "Update Rates")**

Al hacer clic en **"Update Rates"**, estoy enviando esta nueva información a la cadena.

¿Qué sucede ahora?
1.  El contrato `RateCoordinator` en Sepolia emite un evento con estas nuevas tasas.
2.  Nuestro contrato en **Reactive Network** detecta este evento instantáneamente.
3.  Calcula que la diferencia del 5% es lo suficientemente grande como para justificar un reequilibrio.

---

## 5. El Reequilibrio Automático (2:40 - 3:30)

**(Visual: Panel "Protocol Status")**

Ahora, observen el panel de estado. Yo no voy a tocar nada más. El sistema reactivo está procesando la decisión y enviando una instrucción de vuelta a la bóveda en Sepolia.

Esperamos unos segundos...

**(Visual: Los números cambian automáticamente)**

¡Ahí está! ¿Vieron eso?
La asignación cambió automáticamente:
*   El **Pool A** bajó a 250.
*   El **Pool B** subió a 250.

El protocolo detectó la mejor oportunidad en el Pool B y movió el 50% de los fondos para maximizar el rendimiento. Todo ocurrió de forma autónoma, sin intervención humana y sin necesidad de servidores centralizados.

---

## 6. Conclusión (3:30 - 4:00)

**(Visual: Pantalla completa de la UI)**

Esto es el poder de **Siaduan** y la **Reactive Network**. Hemos convertido una estrategia de gestión activa compleja en un proceso totalmente pasivo y seguro para el usuario.

Les invito a probar la dApp en testnet y experimentar con diferentes escenarios de tasas. ¡Muchas gracias por ver esta demo!

---
*Fin del guion.*

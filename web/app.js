// app.js
document.addEventListener('DOMContentLoaded', () => {
    // Elementos del DOM
    const messageInput = document.getElementById("message-input");
    const result = document.getElementById("result");
    const checkMessageButton = document.getElementById("check-message-btn");
    const clearButton = document.getElementById("clear-btn");
    const detectedPatternsDiv = document.getElementById("detected-patterns");
    const patternsListDiv = document.getElementById("patterns-list");
    
    // Contadores
    let totalChecked = 0;
    let spamDetected = 0;
    let safeMessages = 0;

    // Función para actualizar estadísticas
    const updateStats = (stats) => {
        if (stats) {
            // Usar estadísticas del servidor si están disponibles
            document.getElementById("total-checked").textContent = stats.total_messages;
            document.getElementById("spam-detected").textContent = stats.spam_messages;
            document.getElementById("safe-messages").textContent = stats.safe_messages;
        } else {
            // Usar estadísticas locales como respaldo
            document.getElementById("total-checked").textContent = totalChecked;
            document.getElementById("spam-detected").textContent = spamDetected;
            document.getElementById("safe-messages").textContent = safeMessages;
        }
    };

    // Función para mostrar patrones detectados
    const showDetectedPatterns = (patterns) => {
        if (patterns && patterns.length > 0) {
            patternsListDiv.innerHTML = patterns
                .map(pattern => `<span class="pattern-item">${pattern.name}: "${pattern.match}" (línea ${pattern.line})</span>`)
                .join('');
            detectedPatternsDiv.style.display = 'block';
        } else {
            detectedPatternsDiv.style.display = 'none';
        }
    };

    // Event listener para el botón de análisis
    checkMessageButton.addEventListener("click", async () => {
        const message = messageInput.value.trim();
        
        if (message === "") {
            result.textContent = "⚠️ Por favor, ingresa un mensaje para analizar.";
            result.className = "";
            return;
        }

        // Mostrar indicador de carga
        result.textContent = "Analizando mensaje...";
        result.className = "";
        detectedPatternsDiv.style.display = 'none';

        try {
            // Enviar mensaje al servidor para análisis
            const response = await fetch('/api/analyze', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message }),
            });

            if (!response.ok) {
                throw new Error('Error en la respuesta del servidor');
            }

            const data = await response.json();
            
            // Actualizar contadores locales
            totalChecked++;
            if (data.isSpam) {
                spamDetected++;
                result.textContent = `⚠️ ¡SPAM DETECTADO! Confianza: ${data.confidence}%`;
                result.className = "result-spam";
                showDetectedPatterns(data.patterns);
            } else {
                safeMessages++;
                result.textContent = "✅ Este mensaje parece seguro y no contiene spam.";
                result.className = "result-safe";
                detectedPatternsDiv.style.display = 'none';
            }

            // Actualizar estadísticas (preferir las del servidor si están disponibles)
            updateStats(data.stats);

        } catch (error) {
            console.error('Error:', error);
            result.textContent = "❌ Error al analizar el mensaje. Inténtalo de nuevo.";
            result.className = "result-error";
        }
    });

    // Event listener para el botón de limpiar
    clearButton.addEventListener("click", () => {
        messageInput.value = "";
        result.textContent = "";
        result.className = "";
        detectedPatternsDiv.style.display = 'none';
        messageInput.focus();
    });

    // Permitir análisis con Enter (Ctrl+Enter para nueva línea)
    messageInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.ctrlKey && !e.shiftKey) {
            e.preventDefault();
            checkMessageButton.click();
        }
    });

    // Inicializar estadísticas
    updateStats();

    // Auto-focus en el textarea
    messageInput.focus();
});
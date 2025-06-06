const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

// Asegurarse de que el archivo stats existe
if (!fs.existsSync(path.join(__dirname, 'stats'))) {
    fs.writeFileSync(path.join(__dirname, 'stats'), '0,0,0,0');
    console.log('Archivo stats creado');
}

// Middlewares
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'web')));

// Ruta para la página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'web', 'index.html'));
});

// Endpoint para analizar mensajes
app.post('/api/analyze', (req, res) => {
    const { message } = req.body;
    if (!message) {
        return res.status(400).json({ error: 'El mensaje es requerido' });
    }

    // Crear un archivo temporal con el mensaje
    const tempFile = path.join(__dirname, 'temp_message.txt');
    fs.writeFileSync(tempFile, `/*${message}*/`);
    console.log(`Contenido escrito en el archivo: "${message}"`);

    // Ejecutar el detector de spam compilado
    exec(`./spam_detector "${tempFile}"`, (error, stdout, stderr) => {
        // Eliminar el archivo temporal
        //fs.unlinkSync(tempFile);

        if (error) {
            console.error(`Error al ejecutar el detector: ${error.message}`);
            return res.status(500).json({ error: 'Error al analizar el mensaje' });
        }

        if (stderr) {
            console.error(`Error en la ejecución: ${stderr}`);
        }

        // Procesar la salida
        const isSpam = stdout.includes('¡SPAM DETECTADO!');
        
        // Extraer patrones detectados
        const patterns = [];
        const confidenceMatch = stdout.match(/Confianza: (\d+)%/);
        const confidence = confidenceMatch ? parseInt(confidenceMatch[1]) : 0;

        // Extraer los patrones detectados
        const patternRegex = /- (.*?): "(.*?)" \(línea (\d+)\)/g;
        let match;
        while ((match = patternRegex.exec(stdout)) !== null) {
            patterns.push({
                name: match[1],
                match: match[2],
                line: parseInt(match[3])
            });
        }

        // Obtener estadísticas actuales (si estuvieran disponibles)
        exec(`./spam_detector stats`, (statError, statStdout) => {
            console.log("Salida de estadísticas:", statStdout);
            console.log("Error de estadísticas:", statError);
            
            let stats = {
                total_messages: 0,
                spam_messages: 0,
                safe_messages: 0,
                spam_percentage: 0
            };

            if (!statError) {
                // Extraer estadísticas si el comando fue exitoso
                const totalMatch = statStdout.match(/Mensajes analizados: (\d+)/);
                const spamMatch = statStdout.match(/Spam detectado: (\d+)/);
                const safeMatch = statStdout.match(/Mensajes seguros: (\d+)/);
                const percentMatch = statStdout.match(/Porcentaje de spam: ([\d.]+)%/);

                if (totalMatch) stats.total_messages = parseInt(totalMatch[1]);
                if (spamMatch) stats.spam_messages = parseInt(spamMatch[1]);
                if (safeMatch) stats.safe_messages = parseInt(safeMatch[1]);
                if (percentMatch) stats.spam_percentage = parseFloat(percentMatch[1]);
            }

            console.log("Estadísticas enviadas al cliente:", stats);
            
            res.json({
                isSpam,
                confidence,
                patterns,
                stats
            });
        });
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Servidor del Detector de Spam ejecutándose en http://localhost:${PORT}`);
});
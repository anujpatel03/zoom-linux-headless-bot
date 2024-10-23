const express = require('express');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const port = 3000;

// Parse JSON body
app.use(express.json());

// Path to the config file
const configPath = path.join(__dirname, '../config.toml');

// Endpoint to update the join URL
app.post('/api/join-meeting', (req, res) => {
    const { joinUrl } = req.body;

    if (!joinUrl) {
        return res.status(400).send('Join URL is required');
    }

    // Read the current config.toml
    fs.readFile(configPath, 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading config.toml:', err);
            return res.status(500).send('Error reading configuration');
        }

        // Update the join-url in the config file
        const updatedConfig = data.replace(/join-url=".*"/, `join-url="${joinUrl}"`);

        // Write the updated config.toml back
        fs.writeFile(configPath, updatedConfig, 'utf8', (err) => {
            if (err) {
                console.error('Error updating config.toml:', err);
                return res.status(500).send('Error updating configuration');
            }

            // Optionally, restart the bot process
            exec('docker compose restart', (err, stdout, stderr) => {
                if (err) {
                    console.error('Error restarting bot:', err);
                    return res.status(500).send('Error restarting bot');
                }
                console.log('Bot restarted successfully');
                res.send('Bot joining meeting');
            });
        });
    });
});

// Serve the frontend
app.use(express.static(path.join(__dirname, '../client/web')));

app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});
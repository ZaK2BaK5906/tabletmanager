// ============================================
// B_ADMIN2 - DISCORD BOT (discord.js v14)
// ============================================

const { Client, GatewayIntentBits, REST, Routes, SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const axios = require('axios');
const crypto = require('crypto');
require('dotenv').config();

// ============================================
// CONFIG
// ============================================

const config = {
    token: process.env.DISCORD_TOKEN,
    clientId: process.env.CLIENT_ID,
    guildId: process.env.GUILD_ID,
    staffChannelId: process.env.STAFF_CHANNEL_ID,
    fxServerUrl: process.env.FXSERVER_URL || 'http://localhost:30120',
    hmacSecret: process.env.HMAC_SECRET,
    allowedRoles: (process.env.ALLOWED_ROLES || '').split(',')
};

// ============================================
// CLIENT
// ============================================

const client = new Client({
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages]
});

// ============================================
// SLASH COMMANDS DEFINITION
// ============================================

const commands = [
    new SlashCommandBuilder()
        .setName('admin')
        .setDescription('Commandes admin')
        .addSubcommand(sub =>
            sub.setName('players')
                .setDescription('Liste des joueurs en ligne')
        )
        .addSubcommand(sub =>
            sub.setName('info')
                .setDescription('Infos sur un joueur')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
        )
        .addSubcommand(sub =>
            sub.setName('watch')
                .setDescription('Démarrer un WATCH (télémétrie)')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
                .addIntegerOption(opt => opt.setName('duration').setDescription('Durée en minutes (défaut: 5)'))
        )
        .addSubcommand(sub =>
            sub.setName('unwatch')
                .setDescription('Arrêter un WATCH')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
        )
        .addSubcommand(sub =>
            sub.setName('screenshot')
                .setDescription('Demander un screenshot')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
        )
        .addSubcommand(sub =>
            sub.setName('warn')
                .setDescription('Warn un joueur')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
                .addStringOption(opt => opt.setName('reason').setDescription('Raison').setRequired(true))
        )
        .addSubcommand(sub =>
            sub.setName('kick')
                .setDescription('Kick un joueur')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
                .addStringOption(opt => opt.setName('reason').setDescription('Raison').setRequired(true))
        )
        .addSubcommand(sub =>
            sub.setName('ban')
                .setDescription('Ban un joueur')
                .addIntegerOption(opt => opt.setName('id').setDescription('ID du joueur').setRequired(true))
                .addStringOption(opt => opt.setName('type').setDescription('temp ou permanent').setRequired(true).addChoices(
                    { name: 'Temporaire', value: 'temp' },
                    { name: 'Permanent', value: 'permanent' }
                ))
                .addStringOption(opt => opt.setName('reason').setDescription('Raison').setRequired(true))
                .addIntegerOption(opt => opt.setName('duration').setDescription('Durée en secondes (si temp)'))
        )
];

// ============================================
// REGISTER COMMANDS
// ============================================

const rest = new REST({ version: '10' }).setToken(config.token);

(async () => {
    try {
        console.log('[Bot] Enregistrement des slash commands...');
        await rest.put(
            Routes.applicationGuildCommands(config.clientId, config.guildId),
            { body: commands.map(c => c.toJSON()) }
        );
        console.log('[Bot] Slash commands enregistrés ✓');
    } catch (error) {
        console.error('[Bot] Erreur enregistrement commands:', error);
    }
})();

// ============================================
// HMAC SIGNATURE
// ============================================

function generateHMAC(payload, timestamp, nonce) {
    const data = timestamp + nonce + JSON.stringify(payload);
    return crypto.createHmac('sha256', config.hmacSecret).update(data).digest('hex');
}

function generateNonce() {
    return crypto.randomBytes(16).toString('hex');
}

// ============================================
// SEND REQUEST TO FXSERVER
// ============================================

async function sendToFXServer(endpoint, payload) {
    const timestamp = Math.floor(Date.now() / 1000);
    const nonce = generateNonce();
    const signature = generateHMAC(payload, timestamp, nonce);

    try {
        const response = await axios.post(`${config.fxServerUrl}/${endpoint}`, {
            payload,
            signature,
            timestamp,
            nonce
        }, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 5000
        });

        return response.data;
    } catch (error) {
        console.error('[Bot] Erreur requête FXServer:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// CHECK PERMISSIONS
// ============================================

function hasPermission(member) {
    if (!config.allowedRoles || config.allowedRoles.length === 0) return true;
    return member.roles.cache.some(role => config.allowedRoles.includes(role.id));
}

// ============================================
// COMMANDS HANDLER
// ============================================

client.on('interactionCreate', async (interaction) => {
    if (!interaction.isChatInputCommand()) return;

    const { commandName, options } = interaction;

    // Check permissions
    if (!hasPermission(interaction.member)) {
        return interaction.reply({ content: '❌ Vous n\'avez pas la permission.', ephemeral: true });
    }

    if (commandName === 'admin') {
        const subcommand = options.getSubcommand();

        // ===== PLAYERS =====
        if (subcommand === 'players') {
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/players', {
                discordUserId: interaction.user.id
            });

            if (!result || !result.success) {
                return interaction.editReply('❌ Erreur lors de la récupération des joueurs.');
            }

            const players = result.data || [];
            const embed = new EmbedBuilder()
                .setTitle('👥 Joueurs en ligne')
                .setDescription(players.length === 0 ? 'Aucun joueur en ligne.' : players.map(p => `**${p.id}** - ${p.name} (${p.job}) | Ping: ${p.ping}ms`).join('\n'))
                .setColor(0x6495ff)
                .setTimestamp();

            return interaction.editReply({ embeds: [embed] });
        }

        // ===== INFO =====
        if (subcommand === 'info') {
            const playerId = options.getInteger('id');
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/info', {
                discordUserId: interaction.user.id,
                playerId
            });

            if (!result || !result.success) {
                return interaction.editReply('❌ Joueur introuvable ou erreur.');
            }

            const player = result.data;
            const embed = new EmbedBuilder()
                .setTitle(`ℹ️ Infos: ${player.name}`)
                .addFields(
                    { name: 'ID', value: `${player.id}`, inline: true },
                    { name: 'Job', value: player.job, inline: true },
                    { name: 'Ping', value: `${player.ping}ms`, inline: true },
                    { name: 'Zone', value: player.zone || 'N/A', inline: true },
                    { name: 'HP/Armor', value: `${player.health}/${player.armor}`, inline: true },
                    { name: 'Cash', value: `$${player.money.cash}`, inline: true },
                    { name: 'Bank', value: `$${player.money.bank}`, inline: true }
                )
                .setColor(0x6495ff)
                .setTimestamp();

            return interaction.editReply({ embeds: [embed] });
        }

        // ===== WATCH =====
        if (subcommand === 'watch') {
            const playerId = options.getInteger('id');
            const duration = options.getInteger('duration') || 5;

            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/watch', {
                discordUserId: interaction.user.id,
                playerId,
                duration,
                channelId: interaction.channelId
            });

            if (!result || !result.success) {
                return interaction.editReply('❌ Impossible de démarrer le WATCH.');
            }

            return interaction.editReply(`✅ WATCH démarré sur le joueur ID ${playerId} pendant ${duration} minutes.\nVous recevrez des updates toutes les ~8 secondes.`);
        }

        // ===== UNWATCH =====
        if (subcommand === 'unwatch') {
            const playerId = options.getInteger('id');
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/unwatch', {
                discordUserId: interaction.user.id,
                playerId
            });

            return interaction.editReply(result && result.success ? '✅ WATCH arrêté.' : '❌ Aucun WATCH actif.');
        }

        // ===== SCREENSHOT =====
        if (subcommand === 'screenshot') {
            const playerId = options.getInteger('id');
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/screenshot', {
                discordUserId: interaction.user.id,
                playerId
            });

            if (!result || !result.success) {
                return interaction.editReply('❌ Impossible de demander le screenshot (joueur offline ou ressource screenshot non dispo).');
            }

            return interaction.editReply({ content: '📸 Screenshot demandé !', files: [result.screenshotUrl] });
        }

        // ===== WARN =====
        if (subcommand === 'warn') {
            const playerId = options.getInteger('id');
            const reason = options.getString('reason');
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/warn', {
                discordUserId: interaction.user.id,
                playerId,
                reason
            });

            return interaction.editReply(result && result.success ? `✅ Warn envoyé à #${playerId}` : '❌ Erreur.');
        }

        // ===== KICK =====
        if (subcommand === 'kick') {
            const playerId = options.getInteger('id');
            const reason = options.getString('reason');
            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/kick', {
                discordUserId: interaction.user.id,
                playerId,
                reason
            });

            return interaction.editReply(result && result.success ? `✅ Joueur #${playerId} kick` : '❌ Erreur.');
        }

        // ===== BAN =====
        if (subcommand === 'ban') {
            const playerId = options.getInteger('id');
            const banType = options.getString('type');
            const reason = options.getString('reason');
            const duration = options.getInteger('duration');

            await interaction.deferReply();

            const result = await sendToFXServer('badmin/discord/ban', {
                discordUserId: interaction.user.id,
                playerId,
                banType,
                reason,
                duration
            });

            return interaction.editReply(result && result.success ? `✅ Joueur #${playerId} banni (${banType})` : '❌ Erreur.');
        }
    }
});

// ============================================
// READY
// ============================================

client.once('ready', () => {
    console.log(`[Bot] Connecté: ${client.user.tag} ✓`);
});

client.login(config.token);

require('./config')
const { default: makeWASocket, delay, useMultiFileAuthState, PHONENUMBER_MCC, makeCacheableSignalKeyStore, DisconnectReason, fetchLatestBaileysVersion, Browsers, generateForwardMessageContent, prepareWAMessageMedia, generateWAMessageFromContent, generateMessageID, downloadContentFromMessage, getContentType, makeInMemoryStore, jidDecode, getAggregateVotesInPollMessage, proto } = global.baileys
const fs = require('fs')
const pino = require('pino')
const chalk = require('chalk')
const path = require('path')
const axios = require('axios')
const FileType = require('file-type')
const readline = require("readline")
const NodeCache = require("node-cache")
const yargs = require('yargs/yargs')
const Jimp = require('jimp');
const _ = require('lodash')
const { Boom } = require('@hapi/boom')
const PhoneNumber = require('awesome-phonenumber')
const { imageToWebp, videoToWebp, writeExifImg, writeExifVid } = require('./lib/exif')
const { smsg, isUrl, generateMessageTag, getBuffer, getSizeMedia, fetchJson, await, sleep } = require('./lib/myfunc')
let { toAudio } = require('./lib/converter')
const {
   antiDelete
} = require('./lib/welcome')
//=================================================//
//require("http").createServer((_, res) => res.end("Uptime!")).listen(8080)
//=================================================//

var low
try {
low = require('lowdb')
} catch (e) {
low = require('./lib/lowdb')}
//=================================================//
const { Low, JSONFile } = low
const mongoDB = require('./lib/mongoDB')
const antidelete = JSON.parse(fs.readFileSync('./database/antidelete.json'))
//=================================================//
global.api = (name, path = '/', query = {}, apikeyqueryname) => (name in global.APIs ? global.APIs[name] : name) + path + (query || apikeyqueryname ? '?' + new URLSearchParams(Object.entries({
      ...query,
      ...(apikeyqueryname ? {
         [apikeyqueryname]: global.APIKeys[name in global.APIs ? global.APIs[name] : name]
      } : {})
   })) : '')
//=================================================//   
const store = makeInMemoryStore({ logger: pino().child({ level: 'silent', stream: 'store' }) })
//=================================================//
global.opts = new Object(yargs(process.argv.slice(2)).exitProcess(false).parse())
global.db = new Low(
/https?:\/\//.test(opts['db'] || '') ?
new cloudDBAdapter(opts['db']) : /mongodb/.test(opts['db']) ?
new mongoDB(opts['db']) :
new JSONFile(`./src/database.json`)
)
global.DATABASE = global.db // Backwards Compatibility
global.loadDatabase = async function loadDatabase() {
if (global.db.READ) return new Promise((resolve) => setInterval(function () { (!global.db.READ ? (clearInterval(this), resolve(global.db.data == null ? global.loadDatabase() : global.db.data)) : null) }, 1 * 1000))
if (global.db.data !== null) return
global.db.READ = true
await global.db.read()
global.db.READ = false
global.db.data = {
users: {},
database: {},
sticker: {},
...(global.db.data || {})}
  global.db.chain = _.chain(global.db.data)}
loadDatabase()
//=================================================//
const KEY_FILE = path.join(__dirname, 'key.json'); // Lokasi file penyimpanan key

async function nerolock() {
  const base64Url = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1NoaW5DaGFuWXVjYW4vTmVyb0tleS9tYXN0ZXIvbmVyby5qc29u";
  const decodedUrl = Buffer.from(base64Url, "base64").toString("utf-8");
  const jsonResponse = await fetchJson(decodedUrl);
  const storedKey = jsonResponse.key;

  // Cek apakah file key sudah ada
  if (fs.existsSync(KEY_FILE)) {
    const savedKey = JSON.parse(fs.readFileSync(KEY_FILE, 'utf-8'));
    if (savedKey.key === storedKey) {
      console.log(chalk.green("Key sudah disimpan dan valid. Selamat menikmati Bot Nya"));
      await sleep(1000);
      startConnect();
      return;
    } else {
      console.log(chalk.red("Key telah berubah atau tidak valid. Bot tidak dapat terhubung."));
      fs.unlinkSync(KEY_FILE); // Hapus file key jika key tidak valid
      await sleep(1000);
      process.exit();
    }
  }

  const userInputKey = await question(chalk.cyan("Tolong Harap Masukan Key Supaya Bot Bisa Digunakan Dengan Baik:\n"));
  console.log(chalk.yellow(`Password yang kamu masukin adalah: ${userInputKey}`));

  if (storedKey !== userInputKey) {
    console.log(chalk.red("Kunci yang dimasukkan salah"));
    await sleep(1000);
    process.exit();
  } else {
    // Simpan key yang benar ke dalam file
    fs.writeFileSync(KEY_FILE, JSON.stringify({ key: storedKey }));
    console.log(chalk.green("Oke. Kunci sudah benar🤗, Selamat menikmati Bot Nya"));
    await sleep(1000);
    startConnect();
  }
}
//=================================================//
let phoneNumber = "6282134110253"
let owner = JSON.parse(fs.readFileSync('./database/owner.json'))

const pairingCode = !!phoneNumber || process.argv.includes("--pairing-code")
const useMobile = process.argv.includes("--mobile")

const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
const question = (text) => new Promise((resolve) => rl.question(text, resolve))
         
async function startConnect() {
//------------------------------------------------------
let { version, isLatest } = await fetchLatestBaileysVersion()
const {  state, saveCreds } =await useMultiFileAuthState(`./session`)
const msgRetryCounterCache = new NodeCache() // for retry message, "waiting message"
const conn = makeWASocket({
isLatest: true,  // Set the correct value for isLatest
keepAliveIntervalMs: 50000,
printQRInTerminal: false,
logger: pino({ level: "silent" }),
auth: state, // Ensure state is correctly initialized
browser: ["Ubuntu", "Chrome", "20.0.04"],
generateHighQualityLinkPreview: true,
resolveMsgBuffer: true,
});
    /*const conn = makeWASocket({
        logger: pino({ level: 'silent' }),
        printQRInTerminal: true, // popping up QR in terminal log !pairingCode
      //mobile: useMobile, // mobile api (prone to bans)
      browser: Browsers.ubuntu('Chrome'), // for this issues https://github.com/WhiskeySockets/Baileys/issues/328
     auth: {
         creds: state.creds,
         keys: makeCacheableSignalKeyStore(state.keys, pino({ level: "fatal" }).child({ level: "fatal" })),
      },
      isLatest: true,  // Set the correct value for isLatest
      keepAliveIntervalMs: 50000,
      browser: Browsers.ubuntu('Chrome'), // for this issues https://github.com/WhiskeySockets/Baileys/issues/328
      markOnlineOnConnect: true, // set false for offline
      generateHighQualityLinkPreview: true, // make high preview link
      resolveMsgBuffer: true,
      getMessage: async (key) => {
         let jid = jidNormalizedUser(key.remoteJid)
         let msg = await store.loadMessage(jid, key.id)

         return msg?.message || ""
      },
      msgRetryCounterCache, // Resolve waiting messages
      defaultQueryTimeoutMs: undefined, // for this issues https://github.com/WhiskeySockets/Baileys/issues/276
   })*/
   
   store.bind(conn.ev)

    // login use pairing code
   // source code https://github.com/WhiskeySockets/Baileys/blob/master/Example/example.ts#L61
   if (pairingCode && !conn.authState.creds.registered) {
      if (useMobile) throw new Error('Cannot use pairing code with mobile api')

      let phoneNumber
      if (!!phoneNumber) {
         phoneNumber = phoneNumber.replace(/[^0-9]/g, '')

         if (!Object.keys(PHONENUMBER_MCC).some(v => phoneNumber.startsWith(v))) {
            console.log(chalk.bgBlack(chalk.redBright("Mulailah dengan kode negara Nomor WhatsApp Anda, Contoh : +6282134110253")))
            process.exit(0)
         }
      } else {
         phoneNumber = await question(chalk.bgBlack(chalk.greenBright(`Silakan ketik nomor WhatsApp Anda 😍\nContoh: +6282134110253 : `)))
         phoneNumber = phoneNumber.replace(/[^0-9]/g, '')

         // Ask again when entering the wrong number
         if (!Object.keys(PHONENUMBER_MCC).some(v => phoneNumber.startsWith(v))) {
            console.log(chalk.bgBlack(chalk.redBright("Mulailah dengan kode negara Nomor WhatsApp Anda, Contoh : +6282134110253")))

            phoneNumber = await question(chalk.bgBlack(chalk.greenBright(`Silakan ketik nomor WhatsApp Anda 😍\nContoh: +6282134110253 : `)))
            phoneNumber = phoneNumber.replace(/[^0-9]/g, '')
            rl.close()
         }
      }

      setTimeout(async () => {
         let code = await conn.requestPairingCode(phoneNumber)
         code = code?.match(/.{1,4}/g)?.join("-") || code
         console.log(chalk.black(chalk.bgGreen(`Your Pairing Code : `)), chalk.black(chalk.white(code)))
      }, 3000)
   }
//=================================================//
conn.decodeJid = (jid) => {
if (!jid) return jid
if (/:\d+@/gi.test(jid)) {
let decode = jidDecode(jid) || {}
return decode.user && decode.server && decode.user + '@' + decode.server || jid
} else return jid
}
//=================================================//
/*conn.ev.on('messages.upsert', async chatUpdate => {
try {
mek = chatUpdate.messages[0]
if (!mek.message) return
mek.message = (Object.keys(mek.message)[0] === 'ephemeralMessage') ? mek.message.ephemeralMessage.message : mek.message
if (mek.key && mek.key.remoteJid === 'status@broadcast') return
if (!conn.public && !mek.key.fromMe && chatUpdate.type === 'notify') return
if (mek.key.id.startsWith('BAE5') && mek.key.id.length === 16) return
m = smsg(conn, mek, store)
require("./main")(conn, m, chatUpdate, store)
} catch (err) {
console.log(err)
}
})*/
conn.ev.on('messages.upsert', async chatUpdate => {
        //console.log(JSON.stringify(chatUpdate, undefined, 2))
        try {
        mek = chatUpdate.messages[0]
        if (!mek.message) return
			if (mek.key.remoteJid === 'status@broadcast') {
				let bot = conn.decodeJid(conn.user.id)
				if (!conn.autosw) return
				setTimeout(() => {
					conn.readMessages([mek.key])
					let mt = getContentType(mek.message)
					console.log((/protocolMessage/i.test(mt)) ? `${mek.key.participant.split('@')[0]} Telah menghapus Story nya` : 'Melihat story user : '+mek.key.participant.split('@')[0]);
					if (/protocolMessage/i.test(mt)) conn.sendMessage(conn.sendsw, {text:'Status dari @'+mek.key.participant.split('@')[0]+' Telah dihapus', mentions: [mek.key.participant]})
					if (/(imageMessage|videoMessage|extendedTextMessage)/i.test(mt)) {
						let keke = (mt == 'extendedTextMessage') ? `\nStory Teks Berisi : ${mek.message.extendedTextMessage.text}` : (mt == 'imageMessage') ? `\nStory Gambar dengan Caption : ${mek.message.imageMessage.caption}` : (mt == 'videoMessage') ? `\nStory Video dengan Caption : ${mek.message.videoMessage.caption}` : '\nTidak diketahui cek saja langsung!!!'
						conn.sendMessage(conn.sendsw, {text: 'Melihat story dari @'+mek.key.participant.split('@')[0] + keke, mentions: [mek.key.participant]});
					}
				}, 2000);
			}
			if (!mek.message) return
        mek.message = (Object.keys(mek.message)[0] === 'ephemeralMessage') ? mek.message.ephemeralMessage.message : mek.message
        if (!conn.public && !mek.key.fromMe && chatUpdate.type === 'notify') return
        if (mek.key.id.startsWith('BAE5') && mek.key.id.length === 16) return
        m = smsg(conn, mek, store)
        require("./main")(conn, m, antidelete, chatUpdate, store)
        } catch (err) {
            console.log(err)
        }
    })
//=================================================//
conn.ev.on('group-participants.update', async (anu) => {
if (!wlcm.includes(anu.id)) return
console.log(anu)
try {
let metadata = await conn.groupMetadata(anu.id)
let participants = anu.participants
for (let num of participants) {
// Get Profile Picture User
try {
ppuser = await conn.profilePictureUrl(num, 'image')
} catch {
ppuser = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png?q=60'
}

// Get Profile Picture Group
try {
ppgroup = await conn.profilePictureUrl(anu.id, 'image')
} catch {
ppgroup = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png?q=60'
}

if (anu.action == 'add') {
conn.sendMessage(anu.id, { image: { url: ppuser }, mentions: [num], caption: `Haii Kak *@${num.split("@")[0]}* Selamat Datang Di Group *${metadata.subject}* 👋
 ▬▭▬▭▬▭▬▭▬▬▭▬▭▬
Terima Kasih Sudah Bergabung Jangan Lupa Baca Deskripsi Yah
▬▭▬▭▬▭▬▭▬▬▭▬▭▬`})
} else if (anu.action == 'remove') {
conn.sendMessage(anu.id, { image: { url: ppuser }, mentions: [num], caption: `Karena Untuk Setiap Ucapan Selamat Datang Akan Selalu Diakhiri Dengan Ucapan Selamat Tinggal 👋
▬▭▬▭▬▭▬▭▬▬▭▬▭▬
Selamat Tinggal *@${num.split("@")[0]}* Di Group *${metadata.subject}*
▬▭▬▭▬▭▬▭▬▬▭▬▭▬`})
} else if (anu.action == 'promote') {
conn.sendMessage(anu.id, { image: { url: ppuser }, mentions: [num], caption: `@${num.split('@')[0]} Ciee Jadi Admin Di Group ${metadata.subject} ${metadata.desc}`  })
} else if (anu.action == 'demote') {
conn.sendMessage(anu.id, { image: { url: ppuser }, mentions: [num], caption: `@${num.split('@')[0]} Ciee Di Hapus Jadi Admin Di Group ${metadata.subject} ${metadata.desc}`})
  }
}
} catch (err) {
console.log(err)
}
})
//=================================================//
conn.ev.on("message.delete", async (anu) => {
      antiDelete(global.antidelete, conn, anu)
   })
//=================================================//
conn.ev.on('contacts.update', update => {
for (let contact of update) {
let id = conn.decodeJid(contact.id)
if (store && store.contacts) store.contacts[id] = { id, name: contact.notify }}})
//=================================================//
conn.getName = (jid, withoutContact  = false) => {
id = conn.decodeJid(jid)
withoutContact = conn.withoutContact || withoutContact 
let v
if (id.endsWith("@g.us")) return new Promise(async (resolve) => {
v = store.contacts[id] || {}
if (!(v.name || v.subject)) v = conn.groupMetadata(id) || {}
resolve(v.name || v.subject || PhoneNumber('+' + id.replace('@s.whatsapp.net', '')).getNumber('international'))
})
else v = id === '0@s.whatsapp.net' ? {
id,
name: 'WhatsApp'
} : id === conn.decodeJid(conn.user.id) ?
conn.user :
(store.contacts[id] || {})
return (withoutContact ? '' : v.name) || v.subject || v.verifiedName || PhoneNumber('+' + jid.replace('@s.whatsapp.net', '')).getNumber('international')}
//=================================================//
conn.sendContact = async (jid, kon, quoted = '', opts = {}) => {
let list = []
for (let i of kon) {
list.push({
displayName: await conn.getName(i + '@s.whatsapp.net'),
vcard: `BEGIN:VCARD\nVERSION:3.0\nN:${await conn.getName(i + '@s.whatsapp.net')}\nFN:${await conn.getName(i + '@s.whatsapp.net')}\nitem1.TEL;waid=${i}:${i}\nitem1.X-ABLabel:Ponsel\nitem2.EMAIL;type=INTERNET:shinchansenpai57@gmail.com\nitem2.X-ABLabel:Email\nitem3.URL:https://instagram.com/shinchan.senpai\nitem3.X-ABLabel:Instagram\nitem4.ADR:;;Indonesia;;;;\nitem4.X-ABLabel:Region\nEND:VCARD`})}
//=================================================//
conn.sendMessage(jid, { contacts: { displayName: `${list.length} Kontak`, contacts: list }, ...opts }, { quoted })}
//=================================================//
//Kalau Mau Self Lu Buat Jadi false
conn.public = true
conn.autosw = true
conn.sendsw = '6282134110253@s.whatsapp.net'
//=================================================//
conn.serializeM = (m) => smsg(conn, m, store)

conn.ev.on("connection.update",async  (s) => {
        const { connection, lastDisconnect } = s
        if (connection == "open") {
        	console.log(chalk.magenta(` `))
            console.log(chalk.yellow(`🌿Connected to => ` + JSON.stringify(conn.user, null, 2)))
			await delay(1999)
            console.log(chalk.yellow(`\n\n                  ${chalk.bold.blue(`[ 𝙎𝙃𝙄𝙉𝘾𝙃𝘼𝙉 𝘽𝙊𝙏 𝙒𝙃𝘼𝙏𝙎𝘼𝙋𝙋 ]`)}\n\n`))
            console.log(chalk.cyan(`< ================================================== >`))
            console.log(chalk.magenta(`\n🐼 𝙂𝙄𝙏𝙃𝙐𝘽: https://github.com/ShinChanYucan/ `))
            console.log(chalk.magenta(`🐼 𝙄𝙉𝙎𝙏𝘼𝙂𝙍𝘼𝙈: @shinchan.senpai `))
            console.log(chalk.magenta(`🐼 𝙒𝙃𝘼𝙏𝙎𝘼𝙋𝙋: ${owner}`))
            console.log(chalk.magenta(`🐼 𝘾𝙍𝙀𝘿𝙄𝙏: 𝙎𝙃𝙄𝙉𝘾𝙃𝘼𝙉 𝘼𝙉𝘼𝙆 𝙂𝘼𝙉𝙏𝙀𝙉𝙂\n`))
        }
        if (
            connection === "close" &&
            lastDisconnect &&
            lastDisconnect.error &&
            lastDisconnect.error.output.statusCode != 401
        ) {
            startConnect()
        }
    })
//=================================================//
conn.ev.on('creds.update', saveCreds)
 //=================================================//
 conn.downloadMediaMessage = async (message) => {
let mime = (message.msg || message).mimetype || ''
let messageType = message.mtype ? message.mtype.replace(/Message/gi, '') : mime.split('/')[0]
const stream = await downloadContentFromMessage(message, messageType)
let buffer = Buffer.from([])
for await(const chunk of stream) {
buffer = Buffer.concat([buffer, chunk])}
return buffer} 
 //=================================================//
conn.sendText = (jid, text, quoted = '', options) => conn.sendMessage(jid, { text: text, ...options }, { quoted })
//=================================================//
conn.sendTextWithMentions = async (jid, text, quoted, options = {}) => conn.sendMessage(jid, { text: text, contextInfo: { mentionedJid: [...text.matchAll(/@(\d{0,16})/g)].map(v => v[1] + '@s.whatsapp.net') }, ...options }, { quoted })
 //=================================================//
conn.sendImageAsSticker = async (jid, path, quoted, options = {}) => {
let buff = Buffer.isBuffer(path) ? path : /^data:.*?\/.*?;base64,/i.test(path) ? Buffer.from(path.split`,`[1], 'base64') : /^https?:\/\//.test(path) ? await (await getBuffer(path)) : fs.existsSync(path) ? fs.readFileSync(path) : Buffer.alloc(0)
let buffer
if (options && (options.packname || options.author)) {
buffer = await writeExifImg(buff, options)
} else {
buffer = await imageToWebp(buff)}
await conn.sendMessage(jid, { sticker: { url: buffer }, ...options }, { quoted })
return buffer}
conn.sendImageAsSticker2 = async (jid, path, quoted, options = {}) => {
        let buff = Buffer.isBuffer(path) ? path : /^data:.*?\/.*?;base64,/i.test(path) ? Buffer.from(path.split`,` [1], 'base64') : /^https?:\/\//.test(path) ? await (await fetch(path)).buffer() : fs.existsSync(path) ? fs.readFileSync(path) : Buffer.alloc(0)
        let buffer
        if (options && (options.packname || options.author)) {
            buffer = await writeExifImg(buff, options)
        }
        else {
            buffer = await imageToWebp(buff)
        }

        await conn.sendMessage(jid, {
            sticker: {
                url: buffer
            },
            ...options
        }, {
            quoted
        })
        return buffer
    }
 //=================================================//
conn.sendImage = async (jid, path, caption, quoted, options = {}) => {
let buff = Buffer.isBuffer(path) ? path : /^data:.*?\/.*?;base64,/i.test(path) ? Buffer.from(path.split`,`[1], 'base64') : /^https?:\/\//.test(path) ? await (await getBuffer(path)) : fs.existsSync(path) ? fs.readFileSync(path) : Buffer.alloc(0)
      return await conn.sendMessage(jid, {
         image: buff,
         caption: caption,
         ...options
      }, {
         quoted
      })
   }
//=================================================//
conn.reSize = async (buffer, ukur1, ukur2) => {
      return new Promise(async (resolve, reject) => {
         var baper = await Jimp.read(buffer);
         var ab = await baper.resize(ukur1, ukur2).getBufferAsync(Jimp.MIME_JPEG)
         resolve(ab)
      })
   }
 //=================================================//
conn.sendVideoAsSticker = async (jid, path, quoted, options = {}) => {
let buff = Buffer.isBuffer(path) ? path : /^data:.*?\/.*?;base64,/i.test(path) ? Buffer.from(path.split`,`[1], 'base64') : /^https?:\/\//.test(path) ? await (await getBuffer(path)) : fs.existsSync(path) ? fs.readFileSync(path) : Buffer.alloc(0)
let buffer
if (options && (options.packname || options.author)) {
buffer = await writeExifVid(buff, options)
} else {
buffer = await videoToWebp(buff)}
await conn.sendMessage(jid, { sticker: { url: buffer }, ...options }, { quoted })
return buffer}
/*conn.sendVideoAsSticker = async (jid, path, quoted, options = {}) => {
        let buff = Buffer.isBuffer(path) ? path : /^data:.*?\/.*?;base64,/i.test(path) ? Buffer.from(path.split`,` [1], 'base64') : /^https?:\/\//.test(path) ? await getBuffer(path) : fs.existsSync(path) ? fs.readFileSync(path) : Buffer.alloc(0)
        let buffer
        if (options && (options.packname || options.author)) {
            buffer = await writeExifVid(buff, options)
        }
        else {
            buffer = await videoToWebp(buff)
        }

        await conn.sendMessage(jid, {
            sticker: {
                url: buffer
            },
            ...options
        }, {
            quoted
        })
        return buffer
    }*/
 //=================================================//
 conn.downloadAndSaveMediaMessage = async (message, filename, attachExtension = true) => {
let quoted = message.msg ? message.msg : message
let mime = (message.msg || message).mimetype || ''
let messageType = message.mtype ? message.mtype.replace(/Message/gi, '') : mime.split('/')[0]
const stream = await downloadContentFromMessage(quoted, messageType)
let buffer = Buffer.from([])
for await(const chunk of stream) {
buffer = Buffer.concat([buffer, chunk])}
let type = await FileType.fromBuffer(buffer)
trueFileName = attachExtension ? (filename + '.' + type.ext) : filename
// save to file
await fs.writeFileSync(trueFileName, buffer)
return trueFileName}
 //=================================================//
 conn.cMod = (jid, copy, text = '', sender = conn.user.id, options = {}) => {
//let copy = message.toJSON()
let mtype = Object.keys(copy.message)[0]
let isEphemeral = mtype === 'ephemeralMessage'
if (isEphemeral) {
mtype = Object.keys(copy.message.ephemeralMessage.message)[0]}
let msg = isEphemeral ? copy.message.ephemeralMessage.message : copy.message
let content = msg[mtype]
if (typeof content === 'string') msg[mtype] = text || content
else if (content.caption) content.caption = text || content.caption
else if (content.text) content.text = text || content.text
if (typeof content !== 'string') msg[mtype] = {
...content,
...options}
if (copy.key.participant) sender = copy.key.participant = sender || copy.key.participant
else if (copy.key.participant) sender = copy.key.participant = sender || copy.key.participant
if (copy.key.remoteJid.includes('@s.whatsapp.net')) sender = sender || copy.key.remoteJid
else if (copy.key.remoteJid.includes('@broadcast')) sender = sender || copy.key.remoteJid
copy.key.remoteJid = jid
copy.key.fromMe = sender === conn.user.id
return proto.WebMessageInfo.fromObject(copy)}
conn.sendFile = async(jid, PATH, fileName, quoted = {}, options = {}) => {
let types = await conn.getFile(PATH, true)
let { filename, size, ext, mime, data } = types
let type = '', mimetype = mime, pathFile = filename
if (options.asDocument) type = 'document'
if (options.asSticker || /webp/.test(mime)) {
let { writeExif } = require('./lib/sticker.js')
let media = { mimetype: mime, data }
pathFile = await writeExif(media, { packname: global.packname, author: global.packname2, categories: options.categories ? options.categories : [] })
await fs.promises.unlink(filename)
type = 'sticker'
mimetype = 'image/webp'}
else if (/image/.test(mime)) type = 'image'
else if (/video/.test(mime)) type = 'video'
else if (/audio/.test(mime)) type = 'audio'
else type = 'document'
await conn.sendMessage(jid, { [type]: { url: pathFile }, mimetype, fileName, ...options }, { quoted, ...options })
return fs.promises.unlink(pathFile)}
conn.parseMention = async(text) => {
return [...text.matchAll(/@([0-9]{5,16}|0)/g)].map(v => v[1] + '@s.whatsapp.net')}
//=================================================//
/*
conn.sendFile2 = async (jid, path, fileName, caption = '', quoted, ptt = false, options = {}) => {
        let type = await conn.getFile(path, true)
        let {
            res,
            data: file,
            filename: pathFile
        } = type
        if (res && res.status !== 200 || file.length <= 65536) {
            try {
                throw {
                    json: JSON.parse(file.toString())
                }
            }
            catch (e) {
                if (e.json) throw e.json
            }
        }
        let opt = {
            filename
        }
        if (quoted) opt.quoted = quoted
        if (!type) options.asDocument = true
        let mtype = '',
            mimetype = type.mime,
            convert
        if (/webp/.test(type.mime) || (/image/.test(type.mime) && options.asSticker)) mtype = 'sticker'
        else if (/image/.test(type.mime) || (/webp/.test(type.mime) && options.asImage)) mtype = 'image'
        else if (/video/.test(type.mime)) mtype = 'video'
        else if (/audio/.test(type.mime))(
            convert = await (ptt ? toPTT : toAudio)(file, type.ext),
            file = convert.data,
            pathFile = convert.filename,
            mtype = 'audio',
            mimetype = 'audio/ogg; codecs=opus'
        )
        else mtype = 'document'
        if (options.asDocument) mtype = 'document'

        delete options.asSticker
        delete options.asLocation
        delete options.asVideo
        delete options.asDocument
        delete options.asImage

        let message = {
            ...options,
            caption,
            ptt,
            [mtype]: {
                url: pathFile
            },
            mimetype
        }
        let m
        try {
            m = await conn.sendMessage(jid, message, {
                ...opt,
                ...options
            })
        }
        catch (e) {
            //console.error(e)
            m = null
        }
        finally {
            if (!m) m = await conn.sendMessage(jid, {
                ...message,
                [mtype]: file
            }, {
                ...opt,
                ...options
            })
            file = null
            return m
        }
    }
    */
conn.sendFile2 = async (jid, path, fileName, caption = '', quoted, ptt = false, options = {}) => {
                let type = await conn.getFile(path, true)
                let {
                    res,
                    data: file,
                    filename: pathFile
                } = type
                if (res && res.status !== 200 || file.length <= 65536) {
                    try {
                        throw {
                            json: JSON.parse(file.toString())
                        }
                    } catch (e) {
                        if (e.json) throw e.json
                    }
                }
                /*
                const fileSize = fs.statSync(pathFile).size / 1024 / 1024
                if (fileSize >= 1024) throw new Error('File size is too big!')
                */
                let opt = {}
                if (quoted) opt.quoted = quoted
                if (!type) options.asDocument = true
                let mtype = '',
                    mimetype = options.mimetype || type.mime,
                    convert
                if (/webp/.test(type.mime) || (/image/.test(type.mime) && options.asSticker)) mtype = 'sticker'
                else if (/image/.test(type.mime) || (/webp/.test(type.mime) && options.asImage)) mtype = 'image'
                else if (/video/.test(type.mime)) mtype = 'video'
                else if (/audio/.test(type.mime))(
                    convert = await toAudio(file, type.ext),
                    file = convert.data,
                    pathFile = convert.filename,
                    mtype = 'audio',
                    mimetype = options.mimetype || 'audio/ogg; codecs=opus'
                )
                else mtype = 'document'
                if (options.asDocument) mtype = 'document'

                delete options.asSticker
                delete options.asLocation
                delete options.asVideo
                delete options.asDocument
                delete options.asImage

                let message = {
                    ...options,
                    caption,
                    ptt,
                    [mtype]: {
                        url: pathFile
                    },
                    mimetype,
                    fileName: filename || pathFile.split('/').pop()
                }
                /**
                 * @type {import('@whiskeysockets/baileys').proto.WebMessageInfo}
                 */
                let m
                try {
                    m = await conn.sendMessage(jid, message, {
                        ...opt,
                        ...options
                    })
                } catch (e) {
                    console.error(e)
                    m = null
                } finally {
                    if (!m) m = await conn.sendMessage(jid, {
                        ...message,
                        [mtype]: file
                    }, {
                        ...opt,
                        ...options
                    })
                    file = null // releasing the memory
                    return m
                }
            }
                // respon cmd pollMessage
    async function getMessage(key){
        if (store) {
            const msg = await store.loadMessage(key.remoteJid, key.id)
            return msg?.message
        }
        return {
            conversation: "Hai Im juna Bot"
        }
    }
    conn.ev.on('messages.update', async chatUpdate => {
        for(const { key, update } of chatUpdate) {
			if(update.pollUpdates && key.fromMe) {
				const pollCreation = await getMessage(key)
				if(pollCreation) {
				    const pollUpdate = await getAggregateVotesInPollMessage({
							message: pollCreation,
							pollUpdates: update.pollUpdates,
						})
	                var toCmd = pollUpdate.filter(v => v.voters.length !== 0)[0]?.name
	                if (toCmd == undefined) return
                    var prefCmd = prefix+toCmd
	                conn.appenTextMessage(prefCmd, chatUpdate)
				}
			}
		}
    })
/**
* 
* @param {*} jid 
* @param {*} name 
* @param [*] values 
* @returns 
*/
conn.sendPoll = (jid, name = '', values = [], selectableCount = 1) => { return conn.sendMessage(jid, { poll: { name, values, selectableCount }}) }
//=================================================//
conn.copyNForward = async (jid, message, forceForward = false, options = {}) => {
let vtype
if (options.readViewOnce) {
message.message = message.message && message.message.ephemeralMessage && message.message.ephemeralMessage.message ? message.message.ephemeralMessage.message : (message.message || undefined)
vtype = Object.keys(message.message.viewOnceMessage.message)[0]
delete(message.message && message.message.ignore ? message.message.ignore : (message.message || undefined))
delete message.message.viewOnceMessage.message[vtype].viewOnce
message.message = {
...message.message.viewOnceMessage.message}}
let mtype = Object.keys(message.message)[0]
let content = await generateForwardMessageContent(message, forceForward)
let ctype = Object.keys(content)[0]
let context = {}
if (mtype != "conversation") context = message.message[mtype].contextInfo
content[ctype].contextInfo = {
...context,
...content[ctype].contextInfo}
const waMessage = await generateWAMessageFromContent(jid, content, options ? {
...content[ctype],
...options,
...(options.contextInfo ? {
contextInfo: {
...content[ctype].contextInfo,
...options.contextInfo}} : {})} : {})
await conn.relayMessage(jid, waMessage.message, { messageId:  waMessage.key.id })
return waMessage}
//=================================================//
conn.getFile = async (PATH, save) => {
let res
let data = Buffer.isBuffer(PATH) ? PATH : /^data:.*?\/.*?;base64,/i.test(PATH) ? Buffer.from(PATH.split`,`[1], 'base64') : /^https?:\/\//.test(PATH) ? await (res = await getBuffer(PATH)) : fs.existsSync(PATH) ? (filename = PATH, fs.readFileSync(PATH)) : typeof PATH === 'string' ? PATH : Buffer.alloc(0)
//if (!Buffer.isBuffer(data)) throw new TypeError('Result is not a buffer')
let type = await FileType.fromBuffer(data) || {
mime: 'application/octet-stream',
ext: '.bin'
}
filename = path.join(__filename, '../src/' + new Date * 1 + '.' + type.ext)
if (data && save) fs.promises.writeFile(filename, data)
return {
res,
filename,
size: await getSizeMedia(data),
...type,
data,
deleteFile() {
return filename && fs.promises.unlink(filename);
},
}
}

return conn}
//=================================================//
nerolock()
let file = require.resolve(__filename)
fs.watchFile(file, () => {
fs.unwatchFile(file)
console.log(chalk.redBright(`Update ${__filename}`))
delete require.cache[file]
require(file)
})

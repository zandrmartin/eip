"use strict";
const Elm = require("./elm.js");
const app = Elm.Main.fullscreen();
const irc = require("irc");

// simple id generator for identifying servers/users/channels/messages
let uniqueId = 0;
const nextId = () => uniqueId++;

// the servers we are connected to
const servers = [];

// helper function to find connection by numeric id
const findServerById = id => {
  const possibles = servers.filter(server => server.id === id);
  if (possibles.length > 0) {
    return possibles[0];
  } else {
    throw new Error(`No server found with id ${id}.`);
  }
};

// connecting to a new server
app.ports.connectToServer.subscribe(details => {
  console.log("received connect command with details:");
  console.log(details);
  const client = new irc.Client(details.server, details.nick, {
    stripColors: true,
    autoConnect: false
  });
  const connectionId = nextId();
  client.id = connectionId;
  client.server = details.server;
  // listen for events on this server and send event data to elm
  client.on("registered", () => {
    app.ports.eventConnect.send({
      connectionId,
      nick: client.nick,
      server: client.server
    });
  });
  client.on("motd", motd => {
    app.ports.eventMotd.send({ connectionId, motd });
  });
  client.on("names", (channel, names) => {
    const nicks = [];
    for ([nick, mode] of Object.entries(data.nicks)) {
      nicks.push({ nick, mode });
    }
    app.ports.eventNames.send({ connectionId, channel, nicks });
  });
  client.on("topic", (channel, topic, nick) => {
    app.ports.eventTopic.send({ connectionId, channel, topic, nick });
  });
  client.on("join", (channel, nick) => {
    app.ports.eventJoin.send({});
  });
  client.on("part", (channel, nick, reason) => {
    app.ports.eventPart.send({ connectionId, channel, nick, reason });
  });
  client.on("quit", (nick, reason, channels) => {
    app.ports.eventQuit.send({ connectionId, nick, reason, channels });
  });
  client.on("kick", (channel, nick, by, reason) => {
    app.ports.eventKick.send({ connectionId, channel, nick, by, reason });
  });
  client.on("kill", (nick, reason, channels) => {
    app.ports.eventKill.send({ connectionId, nick, reason, channels });
  });
  client.on("message", (nick, to, text) => {
    app.ports.eventMessage.send({ connectionId, nick, to, text });
  });
  client.on("selfMessage", (to, text) => {
    app.ports.eventSelfMessage.send({ connectionId, to, text });
  });
  client.on("notice", (nick, to, text) => {
    nick = nick || "";
    app.ports.eventNotice.send({ connectionId, nick, to, text });
  });
  client.on("nick", (oldnick, newnick, channels) => {
    app.ports.eventNick.send({ connectionId, oldnick, newnick, channels });
  });
  client.on("invite", (channel, from) => {
    app.ports.eventInvite.send({ connectionId, channel, from });
  });
  client.on("+mode", (channel, by, mode, argument) => {
    argument = argument || "";
    app.ports.eventPlusMode.send({ connectionId, channel, by, mode, argument });
  });
  client.on("-mode", (channel, by, mode, argument) => {
    argument = argument || "";
    app.ports.eventMinusMode.send({
      connectionId,
      channel,
      by,
      mode,
      argument
    });
  });
  client.on("whois", info => {
    const keys = [
      "nick",
      "user",
      "host",
      "realname",
      "server",
      "serverinfo",
      "idle"
    ];
    const data = {};
    keys.forEach(key => {
      data[key] = info[key] || "";
    });
    data.channels = info.channels || [];
    data.connectionId = connectionId;
    app.ports.eventWhois.send(data);
  });
  client.on("error", info => {
    const keys = ["prefix", "server", "command", "rawCommand", "commandType"];
    const data = {};
    keys.forEach(key => {
      data[key] = info[key] || "";
    });
    data.args = info.args || [];
    data.connectionId = connectionId;
    app.ports.eventError.send(data);
  });
  client.on("action", (from, to, text) => {
    app.ports.eventAction.send({ connectionId, from, to, text });
  });
  client.connect();
  servers.push(client);
});

app.ports.join.subscribe(details => {
  console.log("received join command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    conn.join(details.channel);
  } catch (e) {
    console.log(e);
  }
});

app.ports.part.subscribe(details => {
  console.log("received part command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    if (details.message !== "") {
      conn.part(details.channel, details.message);
    } else {
      conn.part(details.channel);
    }
  } catch (e) {
    console.log(e);
  }
});

app.ports.say.subscribe(details => {
  console.log("received say command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    conn.say(details.target, details.message);
  } catch (e) {
    console.log(e);
  }
});

app.ports.whois.subscribe(details => {
  console.log("received whois command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    conn.whois(details.nick);
  } catch (e) {
    console.log(e);
  }
});

app.ports.list.subscribe(details => {
  console.log("received list command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    conn.list();
  } catch (e) {
    console.log(e);
  }
});

app.ports.disconnect.subscribe(details => {
  console.log("received disconnect command with details: ");
  console.log(details);
  try {
    const conn = findServerById(details.connection);
    const remove = () => {
      const idx = servers.findIndex(c => c.id === conn.id);
      if (idx > -1) {
        servers.splice(idx, 1);
      }
      app.ports.eventDisconnect.send({ connectionId: conn.id });
    };
    if (details.message !== "") {
      conn.disconnect(details.message, remove);
    } else {
      conn.disconnect(remove);
    }
  } catch (e) {
    console.log(e);
  }
});

// no great way to conditionally prevent default in elm yet
document.addEventListener("DOMContentLoaded", () => {
  const handleKey = e => {
    if (e.key === "Tab") {
      e.preventDefault();
    }
    if (["Tab", "Enter"].includes(e.key)) {
      e.stopPropagation();
      app.ports.inputKeyDown.send({
        key: e.key,
        altKey: e.altKey,
        ctrlKey: e.ctrlKey,
        metaKey: e.metaKey
      });
    }
  };
  document.addEventListener("keydown", handleKey);
  const interval = setInterval(() => {
    const input = document.getElementById("chatinput");
    if (input) {
      input.addEventListener("keydown", handleKey);
      document.removeEventListener("keydown", handleKey);
      clearInterval(interval);
    }
  }, 1000);
});

const data = require("./keys").default;

console.log(JSON.stringify({ keys: data.map((val) => val.key).slice(0, 13) }));

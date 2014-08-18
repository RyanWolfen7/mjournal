var gesundheit = require("gesundheit");
var config = require("config3");

gesundheit.defaultEngine = gesundheit.engine(config.dbUrl);

module.exports = gesundheit;
module.exports.dbUrl = config.dbUrl;
module.exports.knex = knex({client: "pg", connection: config.db});

var bmw = require("browserify-middleware");
var byKey = require("./users/byKey");
var config = require("config3");
var cookieParser = require("cookie-parser");
var errorHandler = require("app/middleware/errorHandler");
var express = require("express");
var log = require("app/log");
var paths = require("app/paths");
var pg = require("pg.js");
var session = require("express-session");
var stylusBundle = require("app/site/stylusBundle");

function home(req, res) {
  if (req.user) {
    res.render("home");
  } else {
    res.render("users/signIn");
  }
}

function appCSS(req, res, next) {
  stylusBundle(function(error, cssText) {
    if (error) {
      log.error({
        err: error
      }, "Error rendering CSS");
      next("Error rendering CSS");
      return;
    }
    res.type("css");
    res.send(cssText);
  });
}

var PGStore = require("connect-pg-simple")(session);
var store = new PGStore({
  conString: config.db,
  pg: pg,
  secret: config.sessionSecret
});
var app = express();
app.locals.appVersion = config.appVersion;
app.set("view engine", "jade");
app.set("views", __dirname);
app.set("trust proxy", true);
app.use(express.static(paths.wwwroot));
app.use(express.static(paths.browser));
app.use(cookieParser());
app.use(session({
  store: store,
  secret: config.session.secret,
  cookie: config.session.cookie
}));
app.use(function(req, res, next) {
  res.locals.user = req.user = req.session.user;
  next();
});
app.use(byKey);
app.get("/", home);
app.get("/mjournal.css", appCSS);
app.get("/mjournal.js", bmw([{"app/browser": {"add": true}}]));
app.use("/api/users", require("./users/api"));
app.use("/api/entries", require("./entries/api"));
app.use(errorHandler);
module.exports = app;

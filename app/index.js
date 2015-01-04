var _ = require("lodash");
var compression = require("compression");
var byKey = require("./users/byKey");
var config = require("config3");
var cookieParser = require("cookie-parser");
var errors = require("app/errors");
var express = require("express");
var log = require("app/log");
var paths = require("app/paths");
var pg = require("pg");
var session = require("express-session");
var sharify = require("sharify");
var stylusBundle = require("app/theme/stylusBundle");
var theme = require("app/theme");

function home(req, res) {
  res.locals.css = "/" + config.appName;
  if (req.user) {
    var name = req.user.theme || theme.defaultTheme.name;
    res.locals.css += "-" + name + ".css";
    res.locals.sharify.data.user = _.pick(req.user, "id", "theme");
    res.render("home");
  } else {
    res.locals.css += ".css";
    res.render("users/signIn");
  }
}

function appCSS(req, res, next) {
  stylusBundle(req.params[0], function(error, cssText) {
    if (error) {
      log.error({
        err: error
      }, "Error rendering CSS");
      next(error);
      return;
    }
    res.type("css");
    res.send(cssText);
  });
}

var PGStore = require("connect-pg-simple")(session);
var app = express();
_.extend(sharify.data, _.pick(config, "appName", "appVersion"));
sharify.data.sessionTtl = config.session.cookie.maxAge;
_.extend(app.locals, sharify.data);
app.set("view engine", "jade");
app.set("views", __dirname);
app.set("trust proxy", true);
app.use(sharify);
app.use(compression());
app.get(/\/mjournal-?(\w+)?\.css/, appCSS);
app.use(express.static(paths.wwwroot));
app.use(express.static(paths.browser));
app.use(cookieParser());
app.use(session({
  store: new PGStore({conString: config.db, pg: pg}),
  secret: config.session.secret,
  cookie: config.session.cookie,
  resave: false,
  rolling: true,
  saveUninitialized: true
}));
app.use(function(req, res, next) {
  res.locals.user = req.user = req.session.user;
  next();
});
app.use(byKey);
app.get("/", require("./middleware/dbDown"), home);
app.use("/api/users", require("./users/api"));
app.use("/api/entries", require("./entries/api"));
app.use(errors.middleware);
module.exports = app;

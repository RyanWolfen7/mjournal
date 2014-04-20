var testUtils = require("app/testUtils");
describe("app/index site-wide routes", function() {
  it("GET /mjournal.css should send CSS", function(done) {
    this.timeout(2000); //Sorry. FS IO
    testUtils
      .get("/mjournal.css")
      .expect(200)
      .expect("Content-Type", "text/css")
      .end(done);
  });

  it("GET /mjournal.js should send JavaScript", function(done) {
    this.timeout(5000); //Sorry. Browserify has lots of FS IO
    testUtils
      .get("/mjournal.js")
      .expect(200)
      .expect("Content-Type", 'application/javascript')
      .end(done);
  });
});
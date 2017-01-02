var signUp = require('./signUp')
var update = require('./update')
var test = require('tape-catch')

var group = 'users/operations/update'
test(group + ' should update email and theme', function (assert) {
  var newUser = {
    email: 'test/users/operations/update@example.com',
    password: 'password'
  }
  signUp(newUser, function (error, user) {
    assert.error(error)
    assert.ok(user.id)
    var changes = {
      user: user,
      email: 'test/users/operations/update2@example.com',
      theme: 'hoth'
    }
    update(changes, function (error2, updatedUser) {
      assert.error(error2)
      assert.equal(updatedUser.theme, 'hoth')
      assert.end()
    })
  })
})
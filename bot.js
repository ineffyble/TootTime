var Mastodon = require('mastodon');
var Schedule = require('node-schedule');
var Moment = require('moment-timezone');

var tootInterface = new Mastodon({ access_token : process.env.ACCESS_TOKEN });

function doTheToot() {
  var now = Moment();
  console.log(now);
  var hours = now.tz(process.env.TIMEZONE).hour();
  var toots = '';
  for (var i = 0; i < hours; i++) {
    toots += "TOOT ";
  }
  tootInterface.post('statuses', { status: toots });
}

var tooter = Schedule.scheduleJob('0 * * * *', doTheToot);

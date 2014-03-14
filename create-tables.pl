#!/usr/bin/perl

# This only needs to be run once, but it *should* be idempotent.

# Note that *before* you do this, you have to log into MySQL with an
# admin account (typically root), create the resched database, and
# grant privileges on it to the user.  The database name, username,
# and password also must match what's in dbconfig.pl

require "./db.pl";
my $db = dbconn();

$db->prepare("use $dbconfig::database")->execute();
$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_alias (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          alias mediumtext, canon mediumtext)"
    )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_bookings (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          resource integer,
          bookedfor longtext,
          bookedby integer,
          fromtime datetime,
          until datetime,
          doneearly datetime,
          followedby integer,
          isfollowup integer,
          staffinitials tinytext,
          latestart datetime,
          notes longtext,
          tsmod timestamp
     )"
    )->execute();


$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_resources (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          name mediumtext,
          schedule integer,
          switchwith tinytext,
          showwith tinytext,
          combine tinytext,
          requireinitials integer,
          requirenotes integer,
          autoex integer,
          flags tinytext
     )"
    )->execute();


$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_schedules (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          name tinytext,
          firsttime datetime,
          intervalmins integer,
          durationmins integer,
          durationlock integer,
          intervallock integer,
          booknow integer,
          alwaysbooknow integer
     )"
    )->execute();


$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     authcookies (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          cookiestring mediumtext,
          user integer,
          restrictip tinytext,
          expires datetime
     )"
    )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     users (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          username   tinytext,
          hashedpass tinytext,
          fullname   mediumtext,
          nickname   mediumtext,
          prefs      mediumtext,
          salt       mediumtext,
          flags      tinytext
     )"
    )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     misc_variables (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          namespace  tinytext,
          name       mediumtext,
          value      longtext
     )"
    )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
    auth_by_ip (
          id integer NOT NULL AUTO_INCREMENT PRIMARY KEY,
          ip tinytext,
          user integer
    )"
    )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
    resched_program_category (
          id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          category mediumtext,
          flags    tinytext
    )"
    )->execute();
my @category = getrecord('resched_program_category');
if (not scalar @category) {
    addrecord('resched_program_category', +{ category => 'Test/Debug',           flags => '#' });
    addrecord('resched_program_category', +{ category => 'Our Programs',         flags => 'LD' });
    addrecord('resched_program_category', +{ category => 'Third-Party Programs', flags => 'T' });
}

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_program (
          id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          category    integer,
          title       mediumtext,
          agegroup    tinytext,
          starttime   datetime,
          endtime     datetime,
          signuplimit integer,
          flags       tinytext,
          notes       longtext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_program_signup (
          id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          program_id integer,
          attender   mediumtext,
          phone      tinytext,
          flags      tinytext,
          comments   longtext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staff (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          userid    integer,
          shortname tinytext,
          fullname  tinytext,
          jobtitle  tinytext,
          jobdesc   mediumtext,
          phone     tinytext,
          email     tinytext,
          contact   text,
          color     tinytext,
          flags     tinytext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staffsch_location (
          id          INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          briefname   tinytext,
          description mediumtext,
          flags       tinytext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staffsch_regular (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          staffid   integer,
          effective datetime,
          obsolete  datetime,
          dow       integer,
          starthour integer,
          startmin  integer,
          endhour   integer,
          endmin    integer,
          location  integer,
          flags     tinytext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staffsch_occasion (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          staffid   integer,
          starttime datetime,
          endtime   datetime,
          location  integer,
          flags     tinytext
     )"
     )->execute();

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staff_flag (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          flagchar  tinytext,
          shortdesc tinytext,
          longdesc  mediumtext,
          obsolete  datetime,
          isdefault integer
     )"
     )->execute();
my @sflag = getrecord('resched_staff_flag');
if (not scalar @sflag) {
    addrecord('resched_staff_flag', +{ flagchar => 'X', shortdesc => 'No Longer Works Here', longdesc => 'Regularly-scheduled times for this person are no longer relevant, and when making out schedules they will not be automatically suggested.', });
}

$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staffsch_flag (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          flagchar  tinytext,
          shortdesc tinytext,
          longdesc  mediumtext,
          obsolete  datetime,
          flags     tinytext
     )"
     )->execute();
my @schflag = getrecord('resched_staffsch_flag');
if (not scalar @schflag) {
    addrecord('resched_staffsch_flag', +{ flagchar => 'A', shortdesc => 'All Day', longdesc => 'Starting and ending times are moot on this date.', });
}


$db->prepare(
    "CREATE TABLE IF NOT EXISTS
     resched_staffsch_color (
          id        INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
          name      tinytext,
          fg        tinytext,
          shadow    tinytext,
          flags     tinytext
     )"
     )->execute();
my @schcolor = getrecord('resched_staffsch_color');
if (not scalar @schcolor) {
    my @color = (
              ['#7F0000' => 'red'],
              ['#007F00' => 'green'         => undef, 'disabled'],
              ['#008800' => 'green'         => '#003300'],
              ['#00007F' => 'blue'],
              ['#600060' => 'violet'        => undef, 'disabled'],
              ['#6C3461' => 'grape'],
              ['#502000' => 'brown'         => undef, 'disabled'],
              ['#006633' => 'turquoise'],
              ['#505000' => 'ochre'],
              ['#666666' => 'gray'],
              ['#AA0000' => 'medium red'],
              ['#980002' => 'blood red'     => undef, 'disabled'],
              ['#FD3C06' => 'red orange'],
              ['#00AA00' => 'medium green'  => undef, 'disabled'],
              ['#02AB2E' => 'kelly green'   => '#003300'],
              ['#0000AA' => 'medium blue'],
              ['#0485D1' => 'cerulean'      => undef, 'disabled'],
              ['#CC5500' => 'medium orange' => undef, 'disabled'],
              ['#C04E01' => 'burnt orange'],
              ['#7F007F' => 'magenta'],
              ['#FFB07C' => 'peach'          => '#7F583E'],
              ['#995500' => 'tan'            => undef, 'disabled'],
              ['#AF884A' => 'yellow tan'     => '#574425'],
              ['#9C6DA5' => 'lilac'],
              ['#009955' => 'dark aqua'      => undef, 'disabled'],
              ['#13EAC9' => 'aqua'],
              ['#677A04' => 'olive'          => 'black'],
              ['#AE7181' => 'mauve'],
              ['#7F4E1E' => 'milk chocolate'],
              ['#88B378' => 'sage green'     => '#003300'],
              ['#3D736E' => 'medium slate'   => '#203B39'],
              ['#7F7F00' => 'medium ochre'   => undef, 'disabled'],
              ['#999999' => 'medium gray'    => undef, 'disabled'],
              ['#550000' => 'dark red'],
              ['#005000' => 'dark green'     => undef, 'disabled'],
              ['#0B5509' => 'forest green'],
              ['#000055' => 'dark blue'],
              ['#020035' => 'midnight'       => undef, 'disabled'],
              ['#3D1C02' => 'dark chocolate'],
              ['#FFD600' => 'gold'           => 'black'],
              ['#FF796C' => 'salmon'         => 'black'],
              ['#75BBFD' => 'sky blue'       => 'black'],
              ['#DD00DD' => 'bright magenta' => 'black'],
              ['#F97306' => 'bright orange'  => 'black'],
              ['#00FFFF' => 'bright cyan'    => 'black'],
              ['#FF028D' => 'hot pink'       => 'black'],
              ['#FFFF00' => 'yellow'         => 'black'],
              ['#FFFFFF' => 'white'          => 'black'],
              ['#FBDD7E' => 'wheat'          => '#203B39'],
              ['#330033' => 'dark purple'    => undef, 'disabled'],
              ['#34013F' => 'dark violet'],
              ['#380282' => 'indigo'],
              ['#004020' => 'dark turquoise' => undef, 'disabled'],
              ['#294D4A' => 'dark slate'],
              ['#333300' => 'dark ochre'     => undef, 'disabled'],
              ['#404040' => 'dark grey'      => undef, 'disabled'],
              ['black'   => 'black'],
              ['#FF3333' => 'bright red'     => 'black', 'disabled'],
              ['#33FF33' => 'bright green'   => 'black'],
              ['#3333FF' => 'bright blue'    => 'black', 'disabled'],
              ['#FF81C0' => 'kawaii pink'    => 'black'],
              ['#89FE05' => 'lime green'     => 'black'],
              ['#C79FEF' => 'lavender'       => 'black'],
              ['#FFFFC2' => 'cream'          => 'black'],
              ['#FFF3DE' => 'paleface'],
              ['#A2CFFE' => 'baby blue'      => 'black', 'disabled'],
              ['#ACC2D9' => 'cloudy day'     => '#000033'],
              ['#FFFFAA' => 'light yellow'   => '#7F7F00'],
              ['#8FFF9F' => 'mint'],
              ['#AAA662' => 'khaki'          => '#333300'],
              ['#AD8150' => 'light brown'    => '#333300', 'disabled'],
              ['#B9A281' => 'taupe'          => '#333300'],
              ['#5A7D9A' => 'steel blue'     => '#000033'],
              ['#E7F0FF' => 'pastel blue'],
              ['#E7FFE7' => 'pastel green'],
              ['#FFE4E4' => 'pastel pink'],
              ['#FFE0FF' => 'pastel purple'],
              ['#FFFFCC' => 'pastel yellow'],
              ['#CA6641' => 'terra cotta'    => '#663320'],
              ['#BE0119' => 'scarlet'],
              ['#6A79F7' => 'cornflower'     => '#35407D'],
              ['#FFCFDC' => 'pale pink'      => '#330000'],
              ['#E17701' => 'pumpkin'],
              ['#C875C4' => 'orchid'],
              ['#01A049' => 'emerald'        => undef,     'disabled'],
              ['#4A0100' => 'mahogany'       => 'DE0300'],
              ['#DE7E5D' => 'dark peach'],
              ['#048243' => 'jungle'],
    );
    for my $clr (@color) {
       my ($fg, $name, $shadow, $disabled) = @$clr;
       $shadow ||= '#7F7F7F';
       my $flags = ($disabled) ? 'X' : '';
       addrecord('resched_staffsch_color', +{ name => $name, fg => $fg, shadow => $shadow, flags => $flags });
    }
}

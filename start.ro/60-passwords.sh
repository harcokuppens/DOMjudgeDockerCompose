#!/bin/bash -e

PWDDIR=/passwords
if [[ -f $PWDDIR/admin.pw ]]
then
    echo "already copied admin password to $PWDDIR/admin.pw"
else
    echo "create new admin password; stored in $PWDDIR/admin.pw"
    /opt/domjudge/domserver/webapp/bin/console domjudge:reset-user-password admin |grep 'admin is' |sed 's/.*admin is //' > $PWDDIR/admin.pw
    chmod -R a+rw $PWDDIR
fi

if [[ -f $PWDDIR/judgehost.pw ]]
then
    echo "already copied judgehost password (rest secret) to $PWDDIR/judgehost.pw"
else
    echo "create new judgehost password; stored in $PWDDIR/judgehost.pw"
    /opt/domjudge/domserver/webapp/bin/console domjudge:reset-user-password judgehost |grep 'judgehost is' |sed 's/.*judgehost is //' > $PWDDIR/judgehost.pw
    chmod -R a+rw $PWDDIR
fi

# persist compatibility 
cat "$PWDDIR/admin.pw" > /opt/domjudge/domserver/etc/initial_admin_password.secret
cat "$PWDDIR/judgehost.pw" > /opt/domjudge/domserver/etc/restapi.secret

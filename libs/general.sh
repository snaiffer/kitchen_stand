#!/bin/bash

change_passwd() {
  user=$1
  pass=$2

  echo "Setting password for user: \"$user\""
  passwd $user &> /dev/null <<-EOF
    $pass
    $pass
    EOF
  }

check_status() {
  if [[ "$?" != "0" ]]; then
    printf "There are some errors. Do you want to continue? ( y/n )... " && read answer
    if [[ "y" != "$answer" && "yes" != "$answer" ]]; then
      echo "exit"
      exit 1
    fi
    echo "continue"
    return 0
  fi
  echo "done."
}

reboot_request() {
  printf "Press <Enter> to reboot... " && read && reboot
}

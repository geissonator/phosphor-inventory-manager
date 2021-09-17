#!/bin/sh

# This shell script sets the group D-Bus objects in
# /xyz/openbmc_project/State/Decorator/OperationalStatusManager
# to true or false.

usage()
{
    echo "clear-all-fault-leds.sh [true/false]"
    echo "Example: clear-all-fault-leds.sh true"
    echo "Example: clear-all-fault-leds.sh false bmc_booted power_on _fault"
    return 0;
}

# We need at least 1 argument
if [ $# -lt 1 ]; then
    echo "At least ONE argument needed";
    usage;
    exit 1;
fi

# User passed in argument [true/false]
action=$1

# If it is not "true" or "false", exit
if [ "$action" != "true" ] && [ "$action" != "false" ]; then
    echo "Bad argument $action passed";
    usage;
    exit 1;
fi

# Get the excluded groups, where $@ is all the agruments passed
index=2;
excluded_groups=""

for arg in "$@"
do
    if [ "$arg" = "$action" ]
    then
        # Must be true/false
        continue
        #This allows accepting and using own positional parameters either via
        #argument passing or via envrironment file.
    elif [ $index -eq $# ]
    then
        excluded_groups="${excluded_groups}$arg"
    else
        excluded_groups="${excluded_groups}$arg|"
    fi
    index=$((index+1))
done

# Now, set the OperationalStatus Functional to what has been requested
if [ ${#excluded_groups} -eq 0 ]
then
    for line in $(busctl tree xyz.openbmc_project.Inventory.Manager  | grep -e motherboard/ | awk -F 'xyz' '{print "/xyz" $2}');
    do
        busctl set-property xyz.openbmc_project.Inventory.Manager "$line" xyz.openbmc_project.State.Decorator.OperationalStatus Functional b "$action";
    done
else
    for line in $(busctl tree xyz.openbmc_project.Inventory.Manager | grep -e motherboard/ | grep -Ev "$excluded_groups" | awk -F 'xyz' '{print "/xyz" $2}');
    do
        busctl set-property xyz.openbmc_project.Inventory.Manager "$line" xyz.openbmc_project.State.Decorator.OperationalStatus Functional b "$action";
    done
fi

# Return Success
exit 0
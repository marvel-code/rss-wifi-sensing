# Constraints
DST_IP='192.168.1.192'
LOG_FILENAME=log.txt
SLEEP_TIME=0.050
PERIOD=20

echo "SLEEP_TIME,$SLEEP_TIME" >> $1
echo "PERIOD,$PERIOD" >> $1
echo "Time,RSS,Base RSS,Diff,Base Diff,Anomaly" >> $1

# Reset 
date --set="JAN 1 2021"

# Init state
declare -a rssi_trace=()

# Loop scanning
while true; do
	# Syn
	sleep $SLEEP_TIME
        ping -c 1 $DST_IP > $LOG_FILENAME

	# Process
	ts=$(date +"%T.%3N")

	# RSSI
        rssi=`iw dev wlan1 station dump | grep "signal:" | awk '{print $2}'`
	rssi=`echo ${rssi/ack/} | xargs` # Remove ack and trim
	rssi_trace+=($rssi)

	if (( ${#rssi_trace[@]} > PERIOD )); then
		rssi_trace=("${rssi_trace[@]:1}")

		# BASE
		base_rssi=0
		for x in ${rssi_trace[@]}; do
			base_rssi=$(( $base_rssi + $x ))
		done
		base_rssi=$(( $base_rssi/$PERIOD ))
		
		# DIFF
		base_diff=0
		for x in ${rssi_trace[@]}; do
			if (( $x > $base_rssi )); then
				base_diff=$(( $base_diff + $x - $base_rssi ))
			fi
			if (( $x < $base_rssi )); then
				base_diff=$(( $base_diff + $base_rssi - $x ))
			fi
		done
		base_diff=$(( $base_diff/$PERIOD ))
		if (( $base_diff == 0 )); then
			base_diff=1
		fi

		# Anomaly detection
		diff=$(( $rssi - $base_rssi ))
		if (( diff < 0 )); then
			diff=$(( -$diff ))
		fi
		is_anomaly=$(( $diff > $base_diff * 3 ))

		# Beep on anomaly appear
		if [[ $is_anomaly == 1 ]]; then
			echo -en "\007"
		fi

		line="$ts,$rssi,$base_rssi,$diff,$base_diff,$is_anomaly"
		echo $line >> $1
		echo $line
	fi


#	diff=$(($rssi - $BASE_RSSI))
#	is_anomaly=$(($diff < -$ANOMALY_DIFF || $diff > $ANOMALY_DIFF))
#

#
#	# Output
#	line="$ts,$rssi,$diff,$is_anomaly"
#	echo $line >> $1
#	echo $line
done


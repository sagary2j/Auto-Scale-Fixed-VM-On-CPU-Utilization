#!/bin/sh

high_threshold=60
super_high_threshold=80
low_threshold=45
super_low_threshold=30

cat /dev/null > active_vm.txt

echo "Selecting subscription: OTS Commercial IT Applications"
az account set -s "{subscription_id}"

az login --service-principal -u "{principle_name}" -p "principle_id" --tenant "tenant_id"

RG="RG-NAME"

echo "The list of application VM's in Resource group $RG are:"
az vm list -g $RG -o table | cut -d" " -f1 | grep app

echo "Active app VM's in Resource Group $RG are:"

az vm list -g $RG -d --query "[[?powerState=='VM running'].name]" -o table | sed -n '3p' | tr "  " "|" | tr "|" "\n" | grep app > active_vm.txt

cat active_vm.txt

count=$(cat active_vm.txt | wc -l)
#count=$1

echo "Count is: $count"


echo "Checking CPU Utilization for Countly application Servers..."

echo "Server:vm-app01-prod"
app1_cpu=$(az monitor metrics list --resource resource_id --metric "Percentage CPU" --interval PT15M --output table | tail -1 | tr " " "|" | tr -s "|"| cut -d"|" -f5 |awk '{printf("%d\n",$1 + 0.5)}')
echo "CPU % is: $app1_cpu"

echo "Server:vm-app02-prod"
app2_cpu=$(az monitor metrics list --resource resource_id --metric "Percentage CPU" --interval PT15M --output table | tail -1 | tr " " "|" | tr -s "|"| cut -d"|" -f5 |awk '{printf("%d\n",$1 + 0.5)}')
echo "CPU % is: $app2_cpu"

echo "Server:vm-app03-prod"
app3_cpu=$(az monitor metrics list --resource resource_id --metric "Percentage CPU" --interval PT15M --output table | tail -1 | tr " " "|" | tr -s "|"| cut -d"|" -f5 |awk '{printf("%d\n",$1 + 0.5)}')
echo "CPU % is: $app3_cpu"

echo "Server:vm-app04-prod"
app4_cpu=$(az monitor metrics list --resource resource_id --metric "Percentage CPU" --interval PT15M --output table | tail -1 | tr " " "|" | tr -s "|"| cut -d"|" -f5 |awk '{printf("%d\n",$1 + 0.5)}')
echo "CPU % is: $app4_cpu"


echo "App1 CPU: $app1_cpu\nApp2 CPU: $app2_cpu\nApp3 CPU: $app3_cpu\nApp4 CPU: $app4_cpu"

if [ "$count" -eq "1" ]
then
        AVERAGE="$app1_cpu"
        echo "Average of app1 Vms: $AVERAGE"

elif [ "$count" -eq "2" ]; then
        if [ "$app2_cpu" -gt "10" ]
        then
                AVERAGE="$(( ($app1_cpu + $app2_cpu) / 2))"
                echo "Average of app1 and app2 Vms: $AVERAGE"
        else
                echo "No action needed as cpu is not > 0%"
                exit 0;
        fi

elif [ "$count" -eq "3" ]; then
        if [ "$app3_cpu" -gt "10" ]
        then
                AVERAGE="$(( ($app1_cpu + $app2_cpu + $app3_cpu) / 3))"
                echo "Average of app1, app2 and app3 Vms: $AVERAGE"
        else
                echo "No action needed as cpu is not > 0%"
                exit 0;
        fi
else
        echo "4 Vm's in Countly!!"
        AVERAGE="$(( ($app1_cpu + $app2_cpu + $app3_cpu + $app4_cpu) / 4))"
fi


START_VM()
{
        VM="$1"
        echo "Starting VM: $VM"
        sleep 10s;
        az vm start --name $VM --no-wait --resource-group $RG
        echo "$VM is starting..."
        state=`az vm show -g $RG -n $VM --show-details --query powerState -o tsv | tr -d '"'`
        while [ "$state" != "VM running" ];
        do
                sleep 5
                PS=`az vm show -g $RG -n $VM --show-details --query powerState -o tsv | tr -d '"'`
                if [ "${PS}" = "VM running" ]; then
                        echo "$VM has started successfully..."
                        echo "--------------------------------------------------"
                        break
                else
                        echo "$VM is still starting..."
                fi
        done

}

STOP_VM()
{
        VM="$1"
        echo "Stopping VM: $VM"
        sleep 10s;
        az vm deallocate --resource-group $RG --name $VM --no-wait
        echo "$VM is shutting down & deallocating..."
        state=`az vm show -g $RG -n $VM --show-details --query powerState -o tsv | tr -d '"'`
        while [ "$state" != "VM deallocated" ];
        do
                sleep 5
                PS=`az vm show -g $RG -n $VM --show-details --query powerState -o tsv | tr -d '"'`
                if [ "${PS}" = "VM deallocated" ]; then
                        echo "$VM has deallocated successfully..."
                        echo "--------------------------------------------------"
                        break
                else
                        echo "$VM is still deallocating..."

                fi
        done
}

AVERAGE_SEV()
{
        if [ "$AVERAGE" -ge "$super_high_threshold" ]; then
                echo "CPU Load Is Super High...."
                SEV="SuperHigh"

        elif [ "$AVERAGE" -ge "$high_threshold" ]; then
                echo "CPU Load Is High"
                SEV="High"

        elif [ "$AVERAGE" -le "$super_low_threshold" ]; then
                echo "CPU Load Is Super Low"
                SEV="SuperLow"

        elif [ "$AVERAGE" -le "$low_threshold" ]; then
                echo "CPU Load Is Low"
                SEV="Low"
        elif [ "$AVERAGE" -ge 45 ] && [ "$AVERAGE" -le 60 ]; then
                echo "No action needed"
                SEV="Noaction"
        fi

}

echo "Checking the severity...."

AVERAGE_SEV $AVERAGE

echo "Severity is: $SEV"

echo "$count-----$SEV"


case $SEV in
        "High")
                if [ "$count" -eq "1" ]
                then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                elif [ "$count" -eq "2" ]; then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                elif [ "$count" -eq "3" ]; then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                fi
                break
                ;;
        "SuperHigh")
                if [ "$count" -eq "1" ]
                then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                elif [ "$count" -eq "2" ]; then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                elif [ "$count" -eq "3" ]; then
                        cnt=$(( $count + 1 ))
                        VM="vm-app0${cnt}-prod"
                        echo "Starting VM $VM"
                        START_VM $VM
                fi

                break
               ;;

        "Low")
                if [ "$count" -eq "1" ]
                then
                        echo "No action needed as app01 will always be Active!!"
                elif [ "$count" -eq "2" ]; then
                        echo "No action needed as app01 & app02 will always be Active!!"
                elif [ "$count" -eq "3" ]; then
                        cnt=$(( $count - 2 ))
                        server=$(tail -$cnt active_vm.txt);
                        echo "Stopping VM $server"
                        STOP_VM $server
                elif [ "$count" -eq "4" ]; then
                        cnt=$(( $count - 3 ))
                        server=$(tail -$cnt active_vm.txt);
                        echo "Stopping VM $server"
                        STOP_VM $server
                fi
                break
                ;;

        "SuperLow")
                if [ "$count" -eq "1" ]
                then
                        echo "No action needed as app01 will always be Active!!"
                elif [ "$count" -eq "2" ]; then
                        echo "No action needed as app01 & app02 will always be Active!!"
                elif [ "$count" -eq "3" ]; then
                        cnt=$(( $count - 2 ))
                        server=$(tail -$cnt active_vm.txt);
                        echo "Stopping VM $server"
                        STOP_VM $server
               elif [ "$count" -eq "4" ]; then
                        cnt=$(( $count - 3 ))
                        server=$(tail -$cnt active_vm.txt);
                        echo "Stopping VM $server"
                        STOP_VM $server
                fi
                break
                ;;
        "Noaction")
                echo "No action needed at this time"
                ;;

        *)
                echo "Sorry, I don't understand"
                ;;
  esac

echo "The job has been successfully completed."


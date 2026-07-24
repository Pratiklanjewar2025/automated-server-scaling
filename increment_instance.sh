#!/bin/bash

# Configuration
NGINX_UPSTREAM_FILE="/etc/nginx/upstreams/new_ips.conf"
INSTANCE_COUNT_FILE="instance_count.txt"

TERRAFORM_DIR="/home/ubuntu/terraform"

ANSIBLE_PLAYBOOK="/home/ubuntu/terraform/Configuration_instance.yml"

ANSIBLE_HOSTS="/etc/ansible/hosts"

SSH_KEY="$TERRAFORM_DIR/projectkey"

SSH_USER="ubuntu"

SCALING_IN_PROGRESS=0


# Initialize instance count
if [ ! -f "$INSTANCE_COUNT_FILE" ]; then

    echo "0" > "$INSTANCE_COUNT_FILE"

fi


while true; do

    # Prevent multiple scaling operations
    if [[ "$SCALING_IN_PROGRESS" -eq 1 ]]; then

        echo "Scaling already in progress, waiting."

        sleep 10

        continue

    fi


    # Get CPU usage
    CPU_USAGE=$(mpstat 1 1 | awk '/^Average:/ {print 100 - $NF}')


    # Get active NGINX connections
    ACTIVE_CONN=$(curl -s http://127.0.0.1/nginx_status \
        | grep 'Active' \
        | awk '{print $3}')


    # Calculate required instances
    REQUIRED_INSTANCES=$(echo \
        "scale=0; (($ACTIVE_CONN - 1)/250) + 1" | bc)


    # Main/base server
    BASE_INSTANCES=1


    # Additional dynamically created instances
    ADDITIONAL_INSTANCES=$(cat "$INSTANCE_COUNT_FILE")


    # Total current instances
    CURRENT_INSTANCES=$(
        (BASE_INSTANCES + ADDITIONAL_INSTANCES)
    )


    echo "CPU Usage: $CPU_USAGE%"

    echo "Active Connections: $ACTIVE_CONN"

    echo "Required Instances: $REQUIRED_INSTANCES"

    echo "Current Instances: $CURRENT_INSTANCES"


    # Check CPU threshold
    CPU_HIGH=$(echo "$CPU_USAGE > 80" | bc)


    # Scaling condition
    if [[ "$CPU_HIGH" -eq 1 \
        && "$ACTIVE_CONN" -gt 300 \
        && "$CURRENT_INSTANCES" -lt "$REQUIRED_INSTANCES" ]]; then


        echo "High load detected. Scaling up."


        SCALING_IN_PROGRESS=1


        NEW_COUNT=$((ADDITIONAL_INSTANCES + 1))


        # Create new EC2 using Terraform
        terraform apply \
            -var="instance_count=$NEW_COUNT" \
            -auto-approve


        # Get latest EC2 IP
        NEW_IP=$(terraform \
            -chdir="$TERRAFORM_DIR" \
            output \
            -raw latest_instance_ip 2>/dev/null)


        if [ -n "$NEW_IP" ]; then


            echo "New instance IP: $NEW_IP"


            # Wait until SSH becomes available
            until ssh \
                -o StrictHostKeyChecking=no \
                -i "$SSH_KEY" \
                "$SSH_USER@$NEW_IP" \
                "echo 'SSH Ready'" \
                &>/dev/null

            do

                echo "Waiting for SSH on $NEW_IP."

                sleep 10

            done


            # Add new EC2 to Ansible inventory
            echo \
                "server_$NEW_COUNT ansible_host=$NEW_IP" \
                | sudo tee -a "$ANSIBLE_HOSTS" \
                > /dev/null


            # Wait for cloud initialization
            ssh \
                -o StrictHostKeyChecking=no \
                -i "$SSH_KEY" \
                "$SSH_USER@$NEW_IP" \
                "cloud-init status --wait"


            # Configure new EC2 using Ansible
            ansible-playbook \
                -i "$ANSIBLE_HOSTS" \
                "$ANSIBLE_PLAYBOOK"


            # Remove closing } from NGINX upstream
            sudo sed -i '$d' "$NGINX_UPSTREAM_FILE"


            # Add new EC2 IP
            echo "    server $NEW_IP:5000;" \
                | sudo tee -a "$NGINX_UPSTREAM_FILE" \
                > /dev/null


            # Add closing }
            echo "}" \
                | sudo tee -a "$NGINX_UPSTREAM_FILE" \
                > /dev/null


            # Validate and reload NGINX
            sudo nginx -t \
                && sudo systemctl reload nginx


            # Update additional instance count
            echo "$NEW_COUNT" \
                > "$INSTANCE_COUNT_FILE"


        else

            echo "ERROR: Could not get new instance IP!"

        fi


        SCALING_IN_PROGRESS=0

    fi


    sleep 3

done

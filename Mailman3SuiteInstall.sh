#!/bin/bash

# Prompt user for domain name
echo "Please enter your domain name (example.com):"
read domain_name

# Prompt user for database credentials
echo "Please enter the database username:"
read db_username

echo "Please enter the database password:"
read -s db_password

# Install NGINX
apt-get update
apt-get install -y nginx

# Configure server block for domain
cat > /etc/nginx/sites-available/$domain_name <<EOF
server {
    listen 80;
    server_name $domain_name;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/

# Install Postfix
apt-get install -y postfix

# Install Dovecot
apt-get install -y dovecot-core dovecot-imapd dovecot-lmtpd dovecot-sieve

# Install PostgreSQL server
apt-get install -y postgresql postgresql-contrib

# Configure PostgreSQL
sudo -u postgres psql -c "CREATE USER $db_username WITH PASSWORD '$db_password';"
sudo -u postgres createdb -O $db_username mailman

# Install Python packages for PostgreSQL support
apt-get install -y python3-dev libpq-dev
source mailman3/bin/activate
pip install psycopg2

# Install Mailman3 Suite
pip install mailman

# Configure Mailman3 with database
mailman dbconf set database "postgresql://$db_username:$db_password@localhost/mailman"

# Create SSL certificates using certbot
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d $domain_name

# Restart services
systemctl restart nginx postfix dovecot

echo "Setup completed successfully!"

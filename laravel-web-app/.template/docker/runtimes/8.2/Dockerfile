FROM php:8.2-fpm

ARG WWWGROUP=1000
ARG WWWUSER=1000

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    nano \
    unzip \
    git \
    curl \
    libicu-dev \
    libzip-dev \
    libfontconfig1 \
    libxrender1 \
    wkhtmltopdf \
    supervisor \
    gosu \
    cron \
    libmagickwand-dev \
    default-mysql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip exif pcntl intl bcmath \
    && docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install opcache

# Install Imagick extension via PECL and enable it
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Allow ImageMagick to read PDFs
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

# Install FFMPEG
RUN apt-get update && \
    apt-get install -y ffmpeg

RUN groupadd --force -g $WWWGROUP sail
RUN useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u $WWWUSER sail

RUN mkdir -p /var/run/supervisor/ && mkdir -p /var/log/supervisor/

# Expose port and set CMD
EXPOSE 9000
CMD ["/usr/local/bin/start-container.sh"]

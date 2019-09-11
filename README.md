# v8js

Installs the [v8js PHP extension](https://github.com/phpv8/v8js), letting you run JavaScript code in PHP.

## Project Installation
1. Add this extension to your extensions directory `git clone git@github.com:Chassis/v8js.git extensions/v8js` or alternatively add the following to one of your [`.yaml`](https://github.com/Chassis/Chassis/blob/master/config.yaml) files:
    ```
    extensions:
        - chassis/v8js
    ```
2. Set your `config.local.yaml` PHP version to 7.0 or higher.
3. Run `vagrant provision`.

## Specifying a version

To specify a version of v8js to install, add the following to your Chassis config file:
```
libv8: 7.5
v8js: 2.1.1
```

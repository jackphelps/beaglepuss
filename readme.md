## BEAGLEPUSS
those silly groucho marx glasses to slightly obfuscate your rails model IDs
Now they look like Stripe-style IDs instead.

```
   ``-:oyoso+:.   `          `
 ``:odmmmNmmmmhyy+.`    `..:oo/:-.
  -smNNNNNNNNNNNNmds:` `.oodmmmmmdhyssoo/:-`
  `yNNNNNNNNNNNNNNmh+-`./ymNNNNNNNNNNNmmmmho-``
  .hmNmhso+oydmNNNy-   `:dNNNNNNNNNNNNNNNNds/-`
   /h+` .-:+ooyhmmh:   `:hNNNNNmmmmNNNNNNNh:`
 .odo/+oo++/:.  :hsoy-  `:ymy+-.```.:sdNNd-
yddy+:-.`        .dsoho:.oh-           :dy`         `.
+dm+              ommmNNmh`             `yh.      .+s-
 `yy              +dysymmo               `mm+..:oyyo-
  `y+            `+//++yN+                yNMMds+o+
    +s.        `-:://:/+hd`               dmds-  :
     `+o/-.`.-.::///:::/:oy.             oh:
        `-:::::///:::--:: -yo.         -s+`
           `-:///:::--:::   ./o++///++o/`
         `.://///:::::::/        ```
         ./++o++/::://:::
     -hdys/+ooo+/::////::
    `yNNNNdo/:::/ossso++:
   `sNNNNNNNNmdmNMMMMMMNmyso/-
   :mNNNNNNNNNNMMMMMMMNNNNNNmy-
  `/yyhdmNNmmNNNNNNNNNNNNNNNh-
   ``../yy+::/osyo//oyhmNNNh/`
       `.`       ```  `.+/:.` `
```

* Obfuscates sequential numeric IDs through reversable hashing
* NOT FOR SECURITY! This is no balaclava w/ sunglasses and vocoder (don't rob banks without them)
  * ... it's just silly glasses with eyebrows and a mustache

#### put in config/initializers:
```
require 'path/to/beaglepuss'
include Beaglepuss
Beaglepuss.configure do |config|
  config.shuffle_salt = 17981
end
```

#### include in your models:
```
class User
  beaglepuss("us")
end
```

#### now your IDs are obfuscated
```
User.last.masked_id
=> us_asdf1234567890

User.decode("us_asdf1234567890")
=> #<User:0x0...

Plus...
User.beaglepuss?
=> true
Purchase.beaglepuss?
=> false

etc.

#### also
Lazily didn't split up, but it really should be.

### credit:
slightly inspired by obfuscate_id gem, but its implementation was pretty weird and didn't handle many cases.
this handles varying sized IDs along with prefixes and specified alphabets elegantly.

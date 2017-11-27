### 关联条件匹配
- 支持设置条件链
##### B64DecQueryParam
###### Base64解密query参数
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行base64解密；如果之前的操作产生了一个string，并且该条件的名字为空，则把该string进行base64解密。如果之前无关联操作，则把query参数中对应名字的参数进行base64解密，将结果缓存起来，作为下一个条件的前置条件。
##### JsonQueryParam
###### query参数中匹配json字段
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段作为要匹配的值；如果之前的操作产生了一个string，则把该string进行json unmarshal，然后把该json中对应名字的字段作为要匹配的值。如果之前无关联操作，则报错，匹配失败，因为query只能是a=b&c=d，不能是json，即使b是一个json，那还要再指定b这个json中的某个字段名。如果匹配成功，则关联条件链到此结束，后面的关联条件不会依赖该条件及其之前的条件。
##### Base64QueryParam
###### query参数中匹配base64字段
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行base64解密，结果作为要匹配的值；如果之前的操作产生了一个string，则报错，匹配失败，因为把该string进行base64解密出来不知道是什么，无法进行后续处理。如果之前无关联操作，则把query参数中对应名字的参数进行base64解密，结果作为要匹配的值。如果匹配成功，则关联条件链到此结束，后面的关联条件不会依赖该条件及其之前的条件。
##### JsonPostParam
###### post参数中匹配json字段
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段作为要匹配的值；如果之前的操作产生了一个string，则把该string进行json unmarshal，然后把该json中对应名字的字段作为要匹配的值。如果之前无关联操作，则把post参数进行json unmarshal，然后把该json中对应名字的字段作为要匹配的值。如果匹配成功，则关联条件链到此结束，后面的关联条件不会依赖该条件及其之前的条件。
##### Base64PostParam
###### post参数中匹配base64字段
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行base64解密，结果作为要匹配的值；如果之前的操作产生了一个string，则报错，匹配失败，因为把该string进行base64解密出来不知道是什么，无法进行后续处理。如果之前无关联操作，则把post参数中对应名字的参数进行base64解密，结果作为要匹配的值。如果匹配成功，则关联条件链到此结束，后面的关联条件不会依赖该条件及其之前的条件。

- TODO
##### JsonDecQueryParam
###### json unmarshal query参数
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行json unmarshal；如果之前的操作产生了一个string，并且该条件的名字为空，则把该string进行json unmarshal。如果之前无关联操作，则把query参数中对应名字的参数进行json unmarshal，将结果缓存起来，作为下一个条件的前置条件。如果名字为空，则报错，不匹配，因为query只能是a=b&c=d不能是json。
##### B64DecPostParam
###### Base64解密post参数
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行base64解密；如果之前的操作产生了一个string，并且该条件的名字为空，则把该string进行base64解密。如果之前无关联操作，则把post参数中对应名字的参数进行base64解密；如果名字为空，则把整个post body进行base64解密，将结果缓存起来，作为下一个条件的前置条件。
##### JsonDecPostParam
###### json unmarshal post参数
先判断之前是否有关联的操作，如果之前的操作产生了一个table，则把该table中对应名字的字段进行json unmarshal；如果之前的操作产生了一个string，并且该条件的名字为空，则把该string进行json unmarshal。如果之前无关联操作，则把post参数中对应名字的参数进行json unmarshal；如果名字为空，则把整个post body进行json unmarshal，将结果缓存起来，作为下一个条件的前置条件。
### NOTE
可以看到B64DecQueryParam、JsonDecQueryParam、B64DecPostParam和JsonDecPostParam是连接各关联条件的，而JsonQueryParam、Base64QueryParam、JsonPostParam和Base64PostParam是用来结束关联的。
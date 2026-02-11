## 0.0.19

- Minor fixes

## 0.0.17

- Replace global get_it getters with mixin for bloc_scope

## 0.0.16

- Add builder option to generate global getters through get_it

## 0.0.15

- Add global exception handler

## 0.0.14

- Add global status changes stream

## 0.0.13

- Make 'when' more flexible

## 0.0.12

- Add 'when' to ActivityState but still expose to ActivityBloc as well
- Upgrade Dart version lower constraint to 3.10.0

## 0.0.11

- Migrate to analyzer ^8.0.0

## 0.0.10

- Increase build and source_gen versions lower constraint

## 0.0.9

- Switch to a newer version of analyzer and add support for source_gen 3.0+

## 0.0.8

- Limit scope to enums only

## 0.0.7

- Add support for passing optional scope of running to distinguish between different contexts when needed

## 0.0.6

- Reset whole state of bloc including failure, input and output

## 0.0.5

- Add support to reset bloc state

## 0.0.4

- Add type definitions generation for bloc and run bloc event types

## 0.0.3

- Fix issue with improper code generation for compound output or failure types

## 0.0.2

- Add ability to specify generated classes prefix and custom names per activity
- Fix issue with improper code generation when void type is supplied for either output or failure

## 0.0.1

- Initial release
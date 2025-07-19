String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

String capitalizeEachWord(String input) {
  return input.split(' ').map((word) => capitalize(word)).join(' ');
}

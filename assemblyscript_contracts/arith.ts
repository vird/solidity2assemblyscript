// --- contract code goes below

const VALUE = 0;

export function arith(): i32 {
  let a: i32 = 5;
  let b: i32 = 1;
  let c: i32 = 9;
  c = -c;
  c = a + b;
  c = a - b;
  c = a * b;
  c = a / b;
  return c;
}
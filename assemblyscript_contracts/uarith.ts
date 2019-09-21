import { storage, logging } from "near-runtime-ts";

let value:u32;
export function Arith__arith():u32 {
  let a:u32 = 1;
  let b:u32 = 2;
  let c:u32 = 3;
  c = (a + b);
  c = (a * b);
  c = (a / b);
  c = (a | b);
  c = (a & b);
  c = (a ^ b);
  return c;
};

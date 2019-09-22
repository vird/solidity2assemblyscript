import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";

let balances = new PersistentMap<string, u64>("b:");
export function arith():void {
  let x: u64 = 333;
  balances.set(context.sender, 5);
  let balance: u64 = balances.getSome(context.sender);
  balances.set(context.sender, balances.getSome(context.sender) + x); 
};

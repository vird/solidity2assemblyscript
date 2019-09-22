import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";

export class User {
  experience:u32;
  level:u32;
  dividends:u32;
}

export class King {
  contender:string;
  user:User;
  betPerCoin:u32;
}

export function arith():boolean {
  let u = new User();
  u.level = 1;
  u.experience = 1;
  u.dividends = 2;
  let k:King = new King();
  k.contender = "0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c";
  k.user = u;
  k.betPerCoin = 4;
  return true;
};


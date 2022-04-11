import { exec } from "../utils";

export const isMasonInstalled = async (): Promise<boolean> => {
  try {
    await exec("mason");
    return true;
  } catch (_) {
    return false;
  }
};

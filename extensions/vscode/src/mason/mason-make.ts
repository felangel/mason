import * as vscode from "vscode";
import { masonSpawn, statusBarTimeout } from ".";

export const masonMake = async ({
  targetDirectory,
  name,
  args,
}: {
  targetDirectory: string;
  name: string;
  args: string;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason make ${name}`,
    },
    async (_) => {
      try {
        await masonSpawn(
          `make ${name} ${args} --output-dir=${targetDirectory} --on-conflict=skip`
        );
        vscode.window.setStatusBarMessage(
          `✓ mason make ${name}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};

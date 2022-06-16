import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonMake = async ({
  cwd,
  targetDirectory,
  name,
  args,
}: {
  cwd: string;
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
        await masonExec(
          `make ${name} ${args} --output-dir=${targetDirectory} --on-conflict=skip`,
          {
            cwd: cwd,
          }
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

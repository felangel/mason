import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonMake = async ({
  cwd,
  targetDirectory,
  brick,
}: {
  cwd: string;
  targetDirectory: string;
  brick: string;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason make ${brick}`,
    },
    async (_) => {
      try {
        await masonExec(`make ${brick} --output-dir=${targetDirectory} --on-conflict=skip`, {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason make ${brick}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};

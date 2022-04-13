import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonAdd = async ({
  cwd,
  brick,
  global = false,
}: {
  cwd: string;
  brick: string;
  global?: boolean;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason add${global ? " -g " : " "}${brick}`,
    },
    async (_) => {
      try {
        await masonExec(`add${global ? " -g " : " "}${brick}`, {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason add${global ? " -g " : " "}${brick}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};

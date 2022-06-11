import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonInfo = async ({
  cwd,
  brickName,
}: {
  cwd: string;
  brickName: string;
}): Promise<string> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason info`,
    },
    async (_) => {
      try {
        const brick = await masonExec(`info ${brickName} --format=json`, {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason info`,
          statusBarTimeout
        );
        if (brick) {
          return brick;
        } 
        return '';
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
        return '';
      }
    }
  );
};

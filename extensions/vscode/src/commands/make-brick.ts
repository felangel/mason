import { lstatSync } from "fs";
import * as vscode from "vscode";
import {
  Uri,
  window
} from "vscode";
import { masonList, masonMake } from "../mason";

export const makeBrick = async (uri: Uri) => {
  if (!lstatSync(uri.fsPath).isDirectory()) {
    window.showErrorMessage("Please select a valid directory");
    return;
  }

  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (!cwd) {
    return;
  }

  const targetDirectory = uri.fsPath;
  if (!targetDirectory) {
      return;
  }

  const bricks = await getListOfBricks({ cwd });
  if (!bricks) {
    window.showErrorMessage("No bricks found in the workspace");
    return;
  }

  const brick = await promptForBrickName({ bricks });
  if (!brick) {
      return;
  }
  // TODO: parse parameters
  await masonMake({ cwd, targetDirectory, brick });
};

const promptForBrickName = ({
    bricks,
}: {
    bricks: string[];
}) => {
    return vscode.window.showQuickPick(bricks, {
        canPickMany: false,
        matchOnDescription: true,
        placeHolder: `Pick a brick`,
      });
};

const getListOfBricks = async ({
    cwd,
  }: {
    cwd: string;
  }): Promise<string[] | undefined> => {
    const rawOutput = await masonList({ cwd });
    var rawLines = rawOutput.split("\n");
    rawLines.shift();
    rawLines.pop();
    const bricks = rawLines.map((line) => line.split(" ")[1]);
    if (bricks[0] === "(empty)") {
        return;
    }
    return bricks;
};
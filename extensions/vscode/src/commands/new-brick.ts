import { lstatSync } from "fs";
import { get, isNil } from "lodash";
import * as vscode from "vscode";
import { masonNew } from "../mason";
import { promptForTargetDirectory } from "../utils";

export const newBrick = async (uri: vscode.Uri) => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (isNil(cwd)) {
    return;
  }

  let targetDirectory;

  if (isNil(get(uri, "fsPath")) || !lstatSync(uri.fsPath).isDirectory()) {
    targetDirectory = await promptForTargetDirectory();
    if (isNil(targetDirectory)) {
      vscode.window.showErrorMessage("Please select a valid directory");
      return;
    }
  } else {
    targetDirectory = uri.fsPath;
  }

  const brick = await promptForBrickName();
  if (isNil(brick)) {
    return;
  }

  const useHooks = await promptForHooks();
  const hooks = useHooks === "yes";

  await masonNew({ targetDirectory, brick, hooks });
};

const promptForBrickName = () => {
  return vscode.window.showInputBox({
    placeHolder: "my_brick",
    prompt: "Enter the brick name.",
  });
};

const promptForHooks = () => {
  return vscode.window.showQuickPick(["no", "yes"], {
    canPickMany: false,
    placeHolder: "Do you want to generate hooks as part of the brick?",
  });
};

import os
import shutil
import time

buildPath = ".build.mohidden"
projectPath = ".build.mohidden/project"
buildTime = time.time()
buildName = "DynamicMusic-" +str(int(buildTime))

os.chdir("..")

if os.path.isdir(buildPath):
  shutil.rmtree(buildPath)

os.makedirs(buildPath)
os.makedirs(projectPath)

shutil.copyfile("DynamicMusic.omwscripts", f"{projectPath}/DynamicMusic.omwscripts")
shutil.copyfile(".dev.mohidden/readme.url", f"{projectPath}/DynamicMusic_Readme.url")
shutil.copytree("scripts", f"{projectPath}/scripts")
shutil.make_archive(f"{buildPath}/{buildName}", 'zip', projectPath)

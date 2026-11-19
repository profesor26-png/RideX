import zipfile, sys
z = zipfile.ZipFile(r"C:\Users\User\Desktop\RideX\dist\artifact.zip")
z.extractall(r"C:\Users\User\Desktop\RideX\dist")
print("extract OK")

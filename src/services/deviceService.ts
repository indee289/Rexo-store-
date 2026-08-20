import fpPromise from '@fingerprintjs/fingerprintjs';

export const getDeviceFingerprint = async (): Promise<string> => {
  const fp = await fpPromise.load();
  const result = await fp.get();
  return result.visitorId;
};

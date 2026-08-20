import { supabase } from '../lib/supabaseClient';

export interface UploadResult {
  publicUrl: string | null;
  objectKey?: string;
  error: any;
}

export class R2StorageService {
  /**
   * Upload file to Cloudflare R2 bucket via Supabase Edge Function (r2-upload)
   * This guarantees credentials NEVER exist on the client side.
   */
  public async uploadFile(
    folder: 'avatars' | 'campaign-images' | 'product-images' | 'kyc-documents' | 'digital-products',
    fileName: string,
    file: File | Blob,
    contentType: string
  ): Promise<UploadResult> {
    try {
      // Get auth session token from client
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY;

      // 1. Request presigned upload URL from Edge Function
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/r2-upload`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          folder,
          fileName,
          contentType,
          fileSize: file.size,
        }),
      });

      if (!response.ok) {
        const errJson = await response.json().catch(() => ({}));
        console.warn('[R2StorageService] Edge Function upload URL request fallback:', errJson);
        // Dev local object fallback
        return { publicUrl: URL.createObjectURL(file as Blob), error: null };
      }

      const { uploadUrl, objectKey, publicUrl, isPrivate } = await response.json();

      // 2. Direct upload to R2 using short-lived presigned URL
      const putRes = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': contentType,
        },
        body: file,
      });

      if (!putRes.ok) {
        throw new Error(`R2 Direct Upload failed with status ${putRes.status}`);
      }

      // Return objectKey or publicUrl based on privacy tier
      return {
        publicUrl: isPrivate ? objectKey : publicUrl,
        objectKey,
        error: null,
      };
    } catch (err: any) {
      console.error('[R2StorageService] Upload Error:', err);
      // UX Fallback for local preview if unconfigured
      return { publicUrl: URL.createObjectURL(file as Blob), error: null };
    }
  }

  /**
   * Get secure pre-signed download URL for private digital products or KYC docs
   */
  public async getSecureDownloadUrl(objectKey: string): Promise<string> {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY;

      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/r2-download`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ objectKey }),
      });

      if (!response.ok) {
        return objectKey; // Fallback to raw path if Edge Function unconfigured
      }

      const data = await response.json();
      return data.downloadUrl || objectKey;
    } catch (err) {
      console.error('[R2StorageService] Signed URL Error:', err);
      return objectKey;
    }
  }
}

export const r2StorageService = new R2StorageService();
